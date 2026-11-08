from django.shortcuts import render
from rest_framework import generics
from .models import WorkspaceBooking
from workspaces.models import WorkspaceCapacity
from rest_framework.views import APIView
from .serializers import WorkspaceBookingSerializer
from django.shortcuts import get_object_or_404
import razorpay
from razorpay.errors import SignatureVerificationError
from django.conf import settings
from rest_framework.response import Response
from rest_framework import status
from users.permissions import IsCustomerPermission,IsProviderPermission,IsOwner
from rest_framework.permissions import IsAuthenticated
from datetime import datetime, timedelta
from django.utils import timezone
from django.utils.dateparse import parse_datetime
import json
from rest_framework.exceptions import ValidationError
# Create your views here.


class WorkspaceCheckAvailabilityAPIView(APIView):
    permission_classes = [IsAuthenticated, IsCustomerPermission]

    def post(self, request):
        seat_id = request.data.get('seat_id')
        requested_start = parse_datetime(request.data.get('start_time'))
        requested_end = parse_datetime(request.data.get('end_time'))

        if not seat_id or not requested_start or not requested_end:
            return Response({"error": "Missing seat_id or start_time or end_time."}, status=400)

        if requested_start >= requested_end:
            return Response({"error": "start_time must be before end_time."}, status=400)
        
        if  requested_start.minute != 0 and requested_end.minute !=0 and requested_end.second !=0 and requested_start.second !=0 :
            raise Response({"error": "Invalid timings"}, status=400)

        now = timezone.now()
        if requested_end <= now:
            return Response({"error": "Cannot book a time in the past."}, status=400)

        try:
            seat = WorkspaceCapacity.objects.get(id=seat_id)
        except WorkspaceCapacity.DoesNotExist:
            return Response({"error": "Invalid seat_id"}, status=404)

        capacity = seat.capacity

        overlapping_bookings = WorkspaceBooking.objects.filter(
            seat_id=seat_id,
            status='completed',
            start_time__lt=requested_end,
            end_time__gt=requested_start
        )
        if overlapping_bookings.count() < capacity:
            return Response({"selected_slot_available": True})

        response_data = {
            "selected_slot_available": False
        }

        total_days = (requested_end - requested_start).days

        # Hour-based booking
        if total_days == 0:
            day = requested_start.date()
            try:
                start_of_day = timezone.make_aware(datetime.combine(day, seat.workspace.start_time))
                end_of_day = timezone.make_aware(datetime.combine(day, seat.workspace.end_time))
            except Exception as e:
                return Response({"error": f"Invalid workspace start/end time: {str(e)}"}, status=400)

            bookings_today = WorkspaceBooking.objects.filter(
                seat_id=seat_id,
                status='completed',
                start_time__lt=end_of_day,
                end_time__gt=start_of_day
            ).order_by('start_time')

            # Time slot map (every 30 minutes)
            interval = timedelta(minutes=60)
            free_slots = []
            conflicting_slots = []

            current_time = start_of_day
            while current_time + interval <= end_of_day:
                slot_start = current_time
                slot_end = current_time + interval

                count = bookings_today.filter(
                    start_time__lt=slot_end,
                    end_time__gt=slot_start
                ).count()

                slot_data = {
                    "start_time": slot_start.isoformat(),
                    "end_time": slot_end.isoformat()
                }

                if count >= capacity:
                    conflicting_slots.append(slot_data)
                else:
                    free_slots.append(slot_data)

                current_time += interval

            response_data["conflicting_hours"] = conflicting_slots
            response_data["suggested_free_hours"] = free_slots

        # Day-based booking
        elif 1 <= total_days < 30:
            busy_days = set()
            current_day = requested_start.date()
            end_day = requested_end.date()

            while current_day <= end_day:
                day_start = timezone.make_aware(datetime.combine(current_day, seat.workspace.start_time))
                day_end = timezone.make_aware(datetime.combine(current_day, seat.workspace.end_time))

                count = WorkspaceBooking.objects.filter(
                    seat_id=seat_id,
                    status='completed',
                    start_time__lt=day_end,
                    end_time__gt=day_start
                ).count()

                if count >= capacity:
                    busy_days.add(current_day)

                current_day += timedelta(days=1)

            all_days = [
                (requested_start + timedelta(days=i)).date()
                for i in range((requested_end - requested_start).days + 1)
            ]
            free_days = [day.isoformat() for day in all_days if day not in busy_days]

            response_data["busy_days"] = sorted([d.isoformat() for d in busy_days])
            response_data["suggested_free_days"] = free_days

        # Month-based booking
        else:
            year = requested_start.year
            busy_months = set()

            for month in range(1, 13):
                month_start = timezone.make_aware(datetime(year, month, 1))
                if month == 12:
                    month_end = timezone.make_aware(datetime(year + 1, 1, 1))
                else:
                    month_end = timezone.make_aware(datetime(year, month + 1, 1))

                count = WorkspaceBooking.objects.filter(
                    seat_id=seat_id,
                    status='completed',
                    start_time__lt=month_end,
                    end_time__gt=month_start
                ).count()

                if count >= capacity:
                    busy_months.add(f"{year}-{month:02d}")

            all_months = [f"{year}-{m:02d}" for m in range(1, 13)]
            free_months = [m for m in all_months if m not in busy_months]

            response_data["busy_months"] = sorted(list(busy_months))
            response_data["suggested_free_months"] = free_months

        return Response(response_data)


class WorkspaceBookingCreateView(generics.ListCreateAPIView):
    queryset = WorkspaceBooking.objects.all()
    serializer_class = WorkspaceBookingSerializer
    permission_classes = [IsAuthenticated,IsCustomerPermission]

    def perform_create(self, serializer):
        seat_id = serializer.validated_data.get('seat').id
        requested_start = serializer.validated_data.get('start_time')
        requested_end = serializer.validated_data.get('end_time')

        if not seat_id or not requested_start or not requested_end:
            raise ValidationError({"error": "Missing seat_id or start_time or end_time."},400)

        if requested_start >= requested_end:
            raise ValidationError({"error": "start_time must be before end_time."},400)
        
        if  requested_start.minute != 0 and requested_end.minute !=0 and requested_end.second !=0 and requested_start.second !=0 :
            raise ValidationError({"error": "Invalid timings"},400)
        
        now = timezone.now()
        if requested_end <= now:
            raise ValidationError({"error": "Cannot book a time in the past."},400)

        try:
            seat = WorkspaceCapacity.objects.get(id=seat_id)
        except WorkspaceCapacity.DoesNotExist:
            raise ValidationError({"error": "Invalid seat_id"}, 400)

        capacity = seat.capacity

        overlapping_bookings = WorkspaceBooking.objects.filter(
            seat_id=seat_id,
            status='completed',
            start_time__lt=requested_end,
            end_time__gt=requested_start
        )
        if overlapping_bookings.count() < capacity:
            return super().perform_create(serializer)

        response_data = {
            "selected_slot_available": False
        }

        total_days = (requested_end - requested_start).days

        # Hour-based booking
        if total_days == 0:
            day = requested_start.date()
            try:
                start_of_day = timezone.make_aware(datetime.combine(day, seat.workspace.start_time))
                end_of_day = timezone.make_aware(datetime.combine(day, seat.workspace.end_time))
            except Exception as e:
                return Response({"error": f"Invalid workspace start/end time: {str(e)}"}, status=400)

            bookings_today = WorkspaceBooking.objects.filter(
                seat_id=seat_id,
                status='completed',
                start_time__lt=end_of_day,
                end_time__gt=start_of_day
            ).order_by('start_time')

            # Time slot map (every 30 minutes)
            interval = timedelta(minutes=60)
            free_slots = []
            conflicting_slots = []

            current_time = start_of_day
            while current_time + interval <= end_of_day:
                slot_start = current_time
                slot_end = current_time + interval

                count = bookings_today.filter(
                    start_time__lt=slot_end,
                    end_time__gt=slot_start
                ).count()

                slot_data = {
                    "start_time": slot_start.isoformat(),
                    "end_time": slot_end.isoformat()
                }

                if count >= capacity:
                    conflicting_slots.append(slot_data)
                else:
                    free_slots.append(slot_data)

                current_time += interval

            response_data["conflicting_hours"] = conflicting_slots
            response_data["suggested_free_hours"] = free_slots

        # Day-based booking
        elif 1 <= total_days < 30:
            busy_days = set()
            current_day = requested_start.date()
            end_day = requested_end.date()

            while current_day <= end_day:
                day_start = timezone.make_aware(datetime.combine(current_day, seat.workspace.start_time))
                day_end = timezone.make_aware(datetime.combine(current_day, seat.workspace.end_time))

                count = WorkspaceBooking.objects.filter(
                    seat_id=seat_id,
                    status='completed',
                    start_time__lt=day_end,
                    end_time__gt=day_start
                ).count()

                if count >= capacity:
                    busy_days.add(current_day)

                current_day += timedelta(days=1)

            all_days = [
                (requested_start + timedelta(days=i)).date()
                for i in range((requested_end - requested_start).days + 1)
            ]
            free_days = [day.isoformat() for day in all_days if day not in busy_days]

            response_data["busy_days"] = sorted([d.isoformat() for d in busy_days])
            response_data["suggested_free_days"] = free_days

        # Month-based booking
        else:
            year = requested_start.year
            busy_months = set()

            for month in range(1, 13):
                month_start = timezone.make_aware(datetime(year, month, 1))
                if month == 12:
                    month_end = timezone.make_aware(datetime(year + 1, 1, 1))
                else:
                    month_end = timezone.make_aware(datetime(year, month + 1, 1))

                count = WorkspaceBooking.objects.filter(
                    seat_id=seat_id,
                    status='completed',
                    start_time__lt=month_end,
                    end_time__gt=month_start
                ).count()

                if count >= capacity:
                    busy_months.add(f"{year}-{month:02d}")

            all_months = [f"{year}-{m:02d}" for m in range(1, 13)]
            free_months = [m for m in all_months if m not in busy_months]

            response_data["busy_months"] = sorted(list(busy_months))
            response_data["suggested_free_months"] = free_months

        raise ValidationError(response_data)
        
       
class WorkspaceBookingConfirmView(APIView):
    permission_classes = [IsAuthenticated,IsCustomerPermission,IsOwner]

    def post(self,request):

        res = json.loads(request.data.get('response'))
        # order_id = request.data.get('razorpay_order_id')
        # payment_id = request.data.get('razorpay_payment_id')
        # signature_id = request.data.get('razorpay_signature')
        ord_id = ""
        raz_payment_id = ""
        raz_signature_id = ""

        for key in res.keys():
            if key == 'razorpay_order_id':
                ord_id = res[key]
            elif key == 'razorpay_payment_id':
                raz_payment_id = res[key]
            elif key == 'razorpay_signature':
                raz_signature_id = res[key]


        booking = get_object_or_404(WorkspaceBooking, order_id=ord_id)

        if booking.booked_by_id != request.user.id:
            return Response(
                {'error': 'You are not authorized to confirm this booking'},
                status=status.HTTP_403_FORBIDDEN,
            )

        data = {
            'razorpay_order_id': booking.order_id,
            'razorpay_payment_id': raz_payment_id,
            'razorpay_signature': raz_signature_id,
        }

        client = razorpay.Client(auth=(settings.RAZORPAY_PUBLIC_KEY, settings.RAZORPAY_SECRET_KEY))
        try:
            check = client.utility.verify_payment_signature(data)
        except SignatureVerificationError:
            check = None

        if check is not None:
            WorkspaceBooking.objects.filter(id=booking.id).update(
                payment_id = raz_payment_id,
                signature_id = raz_signature_id,
                status = 'completed',
            )
            order = WorkspaceBooking.objects.filter(id=booking.id).first()
            response = Response({
            'message':'Booking Confirmed',
            'order_id' : ord_id,
            },status=status.HTTP_200_OK)
        else:
            WorkspaceBooking.objects.filter(id=booking.id).update(
                payment_id = raz_payment_id,
                signature_id = raz_signature_id,
                status = 'failed',
            )
            response = Response({
            'message':'Booking Failed',
            'order_id' : ord_id,
            },status=status.HTTP_404_NOT_FOUND)

        return response


class MyBookings(generics.ListAPIView):
    queryset= WorkspaceBooking.objects.all()
    serializer_class = WorkspaceBookingSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs =  super().get_queryset()
        request = self.request
        user = request.user
        if user.user_type == 'provider':
            return qs.filter(seat__workspace__owner_id=user.id)
        else:
            return qs.filter(booked_by_id=user.id)
        return qs




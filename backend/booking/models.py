from django.db import models
from users.models import User
from workspaces.models import WorkspaceCapacity
import razorpay
from django.conf import settings
from django.core.exceptions import ValidationError
from django.utils import timezone

# Create your models here.


class WorkspaceBooking(models.Model):
    Booking_status = {
        'pending' : 'pending',
        'completed' : 'completed',
        'falied' : 'failed',
    }
    order_id = models.CharField(max_length=1000,blank=True,null=True)
    payment_id = models.CharField(max_length=1000,blank=True,null=True)
    signature_id = models.CharField(max_length=1000,blank=True,null=True)
    booked_by = models.ForeignKey(User, on_delete=models.CASCADE)
    seat = models.ForeignKey(WorkspaceCapacity,on_delete=models.CASCADE)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    amount = models.DecimalField(max_digits=15,decimal_places=2,null=True,blank=True)
    status = models.CharField(choices=Booking_status,max_length=9,default='pending')
    booked_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def calculate_amount(self):
        rate_per_hour = self.seat.rate_per_hour
        rate_per_day = self.seat.rate_per_day
        rate_per_month = self.seat.rate_per_month

        duration = self.end_time - self.start_time
        year_diff = self.end_time.year - self.start_time.year
        month_diff = self.end_time.month - self.start_time.month
        if duration.days == 0:
            total_hrs = duration.total_seconds() / 3600
            amount = total_hrs * rate_per_hour
            return round(amount,2)
        elif month_diff == 0 :
            total_days = duration.days
            amount = total_days * rate_per_day
            return round(amount,2)
        elif month_diff > 0 :
            if self.start_time.day == self.end_time.day:
                total_months = year_diff * 12 + month_diff
                amount = total_months * rate_per_month
                return round(amount,2)
    
    def is_full_hour(self):
        if self.start_time.minute == 0 and self.start_time.second == 0 and self.end_time.minute==0 and self.end_time.second == 0:
            return True
        else:
            return False

    def clean(self):
        if self.start_time and self.end_time and self.is_full_hour():
            now = timezone.now()
            if self.end_time>now:
                return super().clean()
            else:
                raise ValidationError("Cannot book a time in past")
        else:
            raise ValidationError("Invalid Booking Time")
        
                
    def save(self,*args,**kwargs):
        self.full_clean()

        self.amount = self.calculate_amount()
        
        client = razorpay.Client(auth=(settings.RAZORPAY_PUBLIC_KEY,settings.RAZORPAY_SECRET_KEY))
        payment  = client.order.create({
            "amount": self.amount * 100,
            "currency" : 'INR',
            "payment_capture" : "1"
        })

        self.order_id = payment['id']

        return super().save(*args,**kwargs)
        





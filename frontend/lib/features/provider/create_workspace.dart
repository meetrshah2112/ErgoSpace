import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/models.dart';
import 'workspace_payload.dart';

class _CapCtl {
  final name = TextEditingController(), desc = TextEditingController(), count = TextEditingController(text: '1');
  final hr = TextEditingController(), day = TextEditingController(), mo = TextEditingController();
  String? image;
  void dispose() { for (final c in [name, desc, count, hr, day, mo]) { c.dispose(); } }
}

class CreateWorkspaceScreen extends ConsumerStatefulWidget {
  const CreateWorkspaceScreen({super.key});
  @override
  ConsumerState<CreateWorkspaceScreen> createState() => _CreateState();
}

class _CreateState extends ConsumerState<CreateWorkspaceScreen> {
  static const _titles = ['Basics', 'Location', 'Details', 'Pricing', 'Photos', 'Review'];
  final _page = PageController();
  int _step = 0;
  bool _busy = false;
  String? _error;
  Map<String, String> _fieldErrors = {};

  final _t = {for (final k in ['name', 'desc', 'a1', 'a2', 'pin', 'city', 'state', 'country', 'lat', 'lon']) k: TextEditingController()};
  String _type = 'Workspace';
  TimeOfDay _open = const TimeOfDay(hour: 9, minute: 0), _close = const TimeOfDay(hour: 18, minute: 0);
  final _amenities = <String>{};
  final _caps = <_CapCtl>[_CapCtl()];
  String? _logo, _bg;
  List<String> _gallery = [];
  final _customAmenity = TextEditingController();
  final _custom = <String>[];
  bool _locating = false;
  String? _locMsg;

  @override
  void initState() { super.initState(); _t['country']!.text = 'India'; }

  @override
  void dispose() {
    _page.dispose();
    _customAmenity.dispose();
    for (final c in _t.values) { c.dispose(); }
    for (final c in _caps) { c.dispose(); }
    super.dispose();
  }

  String _tod(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
  String _show(TimeOfDay t) => t.format(context);
  bool _blank(String k) => _t[k]!.text.trim().isEmpty;

  String? _validate(int s) {
    switch (s) {
      case 0: return _blank('name') ? 'Give your workspace a name.' : (_blank('desc') ? 'Add a short description.' : null);
      case 1:
        for (final k in ['a1', 'pin', 'city', 'state', 'country']) { if (_blank(k)) return 'Please complete the address fields.'; }
        if (double.tryParse(_t['lat']!.text.trim()) == null || double.tryParse(_t['lon']!.text.trim()) == null) return 'Tap "Use my current location" or "Find from address" to set the map location.';
        return null;
      case 2:
        return (_open.hour * 60 + _open.minute) >= (_close.hour * 60 + _close.minute) ? 'Closing time must be after opening time.' : null;
      case 3:
        for (final c in _caps) {
          if (c.name.text.trim().isEmpty || (int.tryParse(c.count.text) ?? 0) < 1) return 'Each capacity needs a name and a seat count.';
          if (c.hr.text.trim().isEmpty && c.day.text.trim().isEmpty && c.mo.text.trim().isEmpty) return 'Add at least one price for each capacity.';
          for (final v in [c.hr, c.day, c.mo]) { if (v.text.trim().isNotEmpty && num.tryParse(v.text.trim()) == null) return 'Prices must be numbers.'; }
        }
        return null;
      default: return null;
    }
  }

  void _go(int s) { setState(() { _step = s; _error = null; }); _page.animateToPage(s, duration: const Duration(milliseconds: 250), curve: Curves.easeOut); }

  void _next() {
    final e = _validate(_step);
    if (e != null) { setState(() => _error = e); return; }
    _go(_step + 1);
  }

  WorkspaceDraft _draft() {
    final d = WorkspaceDraft()
      ..name = _t['name']!.text ..type = _type ..description = _t['desc']!.text
      ..address1 = _t['a1']!.text ..address2 = _t['a2']!.text ..pincode = _t['pin']!.text
      ..city = _t['city']!.text ..state = _t['state']!.text ..country = _t['country']!.text
      ..latitude = _t['lat']!.text ..longitude = _t['lon']!.text
      ..startTime = _tod(_open) ..endTime = _tod(_close)
      ..amenities = _amenities.toList()
      ..logoPath = _logo ..backgroundPath = _bg ..galleryPaths = _gallery;
    d.capacities = [
      for (final c in _caps) CapacityDraft(name: c.name.text.trim(), description: c.desc.text.trim(), capacity: int.parse(c.count.text),
          perHour: num.tryParse(c.hr.text.trim()), perDay: num.tryParse(c.day.text.trim()), perMonth: num.tryParse(c.mo.text.trim()))..imagePath = c.image,
    ];
    return d;
  }

  Future<void> _publish() async {
    if (_busy) return;
    for (var s = 0; s < 4; s++) { final e = _validate(s); if (e != null) { _go(s); setState(() => _error = e); return; } }
    setState(() { _busy = true; _error = null; _fieldErrors = {}; });
    try {
      final fd = await _draft().toFormData();
      await ref.read(workspaceRepoProvider).create(fd);
      ref.invalidate(myWorkspacesProvider);
      if (mounted) { toast(context, 'Workspace published'); context.pop(); }
    } catch (e) {
      final ex = ApiException.from(e);
      if (mounted) setState(() { _busy = false; _error = ex.message; _fieldErrors = ex.fieldErrors; });
    }
  }

  void _setCoords(double lat, double lon) {
    _t['lat']!.text = lat.toStringAsFixed(6);
    _t['lon']!.text = lon.toStringAsFixed(6);
  }

  Future<void> _useCurrentLocation() async {
    setState(() { _locating = true; _locMsg = null; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw 'Turn on location services on your phone.';
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) throw 'Location permission denied. Allow it in app settings.';
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      _setCoords(pos.latitude, pos.longitude);
      try {
        final p = (await placemarkFromCoordinates(pos.latitude, pos.longitude)).first;
        void fill(String k, String? v) { if ((v ?? '').trim().isNotEmpty && _t[k]!.text.trim().isEmpty) _t[k]!.text = v!.trim(); }
        fill('a1', [p.subThoroughfare, p.thoroughfare].where((e) => (e ?? '').isNotEmpty).join(' '));
        fill('a2', p.subLocality);
        fill('city', p.locality);
        fill('state', p.administrativeArea);
        fill('pin', p.postalCode);
        fill('country', p.country);
      } catch (_) {/* address autofill is best-effort */}
      if (mounted) setState(() => _locMsg = 'Location captured. Check the address fields below.');
    } catch (e) {
      if (mounted) setState(() => _locMsg = e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _findFromAddress() async {
    final q = [_t['a1']!.text, _t['a2']!.text, _t['city']!.text, _t['state']!.text, _t['pin']!.text, _t['country']!.text].where((e) => e.trim().isNotEmpty).join(', ');
    if (q.isEmpty) { setState(() => _locMsg = 'Type the address first.'); return; }
    setState(() { _locating = true; _locMsg = null; });
    try {
      final r = await locationFromAddress(q);
      if (r.isEmpty) throw 'Could not find that address. Try the current location option.';
      _setCoords(r.first.latitude, r.first.longitude);
      if (mounted) setState(() => _locMsg = 'Location found from the address.');
    } catch (e) {
      if (mounted) setState(() => _locMsg = e.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _addCustomAmenity() {
    final v = _customAmenity.text.trim();
    if (v.isEmpty) return;
    setState(() { _custom.add(v); _amenities.add(v); _customAmenity.clear(); });
  }

  Future<void> _pickSeatImage(_CapCtl k) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
    if (x != null) setState(() => k.image = x.path);
  }

  Future<void> _pickOne(bool logo) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000);
    if (x != null) setState(() => logo ? _logo = x.path : _bg = x.path);
  }

  Future<void> _pickGallery() async {
    final xs = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 2000);
    if (xs.isNotEmpty) setState(() => _gallery = xs.map((e) => e.path).toList());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Scaffold(
      appBar: AppBar(title: Text('New workspace · ${_titles[_step]}')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
          child: Row(children: [for (var i = 0; i < _titles.length; i++) Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 220), height: 4, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: i <= _step ? c.accent : c.border, borderRadius: BorderRadius.circular(2))))]),
        ),
        Expanded(
          child: PageView(controller: _page, physics: const NeverScrollableScrollPhysics(), children: [
            _scroll([
              ErgoField(label: 'Workspace name', controller: _t['name']!, errorText: _fieldErrors['name']),
              const SizedBox(height: 16),
              Text('TYPE', style: labelStyle(context)), const SizedBox(height: 8),
              Segmented<String>(options: const [('Workspace', 'Workspace'), ('Hotdesk', 'Hot desk')], value: _type, onChanged: (v) => setState(() => _type = v)),
              const SizedBox(height: 16),
              ErgoField(label: 'Description', controller: _t['desc']!, maxLines: 5, errorText: _fieldErrors['description']),
            ]),
            _scroll([
              ErgoField(label: 'Address', controller: _t['a1']!, errorText: _fieldErrors['address_1']), const SizedBox(height: 16),
              ErgoField(label: 'Area', controller: _t['a2']!), const SizedBox(height: 16),
              Row(children: [
                Expanded(child: ErgoField(label: 'Pincode', controller: _t['pin']!, keyboard: TextInputType.number, errorText: _fieldErrors['pincode'])), const SizedBox(width: 12),
                Expanded(child: ErgoField(label: 'City', controller: _t['city']!, errorText: _fieldErrors['city'])),
              ]), const SizedBox(height: 16),
              Row(children: [
                Expanded(child: ErgoField(label: 'State', controller: _t['state']!, errorText: _fieldErrors['state'])), const SizedBox(width: 12),
                Expanded(child: ErgoField(label: 'Country', controller: _t['country']!, errorText: _fieldErrors['country'])),
              ]), const SizedBox(height: 16),
              const SizedBox(height: 4),
              Text('MAP LOCATION', style: labelStyle(context)), const SizedBox(height: 8),
              ErgoButton('Use my current location', icon: Icons.my_location_rounded, loading: _locating, onPressed: _useCurrentLocation), const SizedBox(height: 10),
              ErgoButton('Find from address', secondary: true, icon: Icons.search_rounded, onPressed: _locating ? null : _findFromAddress),
              const SizedBox(height: 10),
              if (_t['lat']!.text.isNotEmpty) Row(children: [
                Icon(Icons.check_circle_rounded, size: 16, color: context.ergo.accent), const SizedBox(width: 6),
                Text('Pinned at ${_t['lat']!.text}, ${_t['lon']!.text}', style: tabular(TextStyle(color: context.ergo.textSecondary, fontSize: 12))),
              ]),
              if (_locMsg != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_locMsg!, style: TextStyle(color: context.ergo.textSecondary, fontSize: 12))),
            ]),
            _scroll([
              Row(children: [
                Expanded(child: _timeBox('Opens', _open, () async { final t = await showTimePicker(context: context, initialTime: _open); if (t != null) setState(() => _open = t); })), const SizedBox(width: 12),
                Expanded(child: _timeBox('Closes', _close, () async { final t = await showTimePicker(context: context, initialTime: _close); if (t != null) setState(() => _close = t); })),
              ]),
              const SizedBox(height: 24),
              Text('AMENITIES', style: labelStyle(context)), const SizedBox(height: 10),
              ref.watch(amenitiesProvider).when(
                loading: () => const Skeleton(height: 80),
                error: (e, _) => ErrorView(e, compact: true, onRetry: () => ref.invalidate(amenitiesProvider)),
                data: (list) => Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final a in [...list.map((e) => e.name), ..._custom.where((cu) => !list.any((e) => e.name.toLowerCase() == cu.toLowerCase()))].map((n) => Amenity(null, n)))
                    GestureDetector(
                      onTap: () => setState(() => _amenities.contains(a.name) ? _amenities.remove(a.name) : _amenities.add(a.name)),
                      child: AnimatedContainer(duration: const Duration(milliseconds: 160), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: _amenities.contains(a.name) ? c.accent : c.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                        child: Text(a.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _amenities.contains(a.name) ? c.onAccent : c.text))),
                    ),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: ErgoField(label: 'Add your own amenity', controller: _customAmenity, hint: 'e.g. Rooftop terrace')), const SizedBox(width: 10),
                Padding(padding: const EdgeInsets.only(top: 22), child: SizedBox(width: 90, child: ErgoButton('Add', secondary: true, onPressed: _addCustomAmenity))),
              ]),
            ]),
            _scroll([
              for (var i = 0; i < _caps.length; i++) _capCard(i),
              ErgoButton('Add another capacity', secondary: true, icon: Icons.add_rounded, onPressed: () => setState(() => _caps.add(_CapCtl()))),
            ]),
            _scroll([
              _photo('Logo', _logo, () => _pickOne(true)), const SizedBox(height: 16),
              _photo('Background image', _bg, () => _pickOne(false)), const SizedBox(height: 16),
              Text('GALLERY', style: labelStyle(context)), const SizedBox(height: 8),
              ErgoButton(_gallery.isEmpty ? 'Select gallery photos' : '${_gallery.length} photos selected', secondary: true, icon: Icons.photo_library_outlined, onPressed: _pickGallery),
            ]),
            _scroll([
              _sum('Name', _t['name']!.text), _sum('Type', _type == 'Hotdesk' ? 'Hot desk' : 'Workspace'),
              _sum('Address', [_t['a1']!.text, _t['a2']!.text, _t['city']!.text, _t['state']!.text, _t['pin']!.text].where((e) => e.trim().isNotEmpty).join(', ')),
              _sum('Hours', '${_show(_open)} – ${_show(_close)}'),
              _sum('Amenities', _amenities.isEmpty ? 'None selected' : _amenities.join(', ')),
              _sum('Capacities', _caps.map((e) => '${e.name.text} (${e.count.text})').join(', ')),
              _sum('Photos', '${_logo != null ? 'Logo · ' : ''}${_bg != null ? 'Background · ' : ''}${_gallery.length} gallery'),
              if (_fieldErrors.isNotEmpty) ...[const SizedBox(height: 8), for (final e in _fieldErrors.entries) Text('${e.key}: ${e.value}', style: TextStyle(color: c.error, fontSize: 12))],
            ]),
          ]),
        ),
        Container(
          decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
          child: SafeArea(top: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error!, style: TextStyle(color: c.error, fontSize: 13))),
              Row(children: [
                if (_step > 0) ...[SizedBox(width: 110, child: ErgoButton('Back', secondary: true, onPressed: _busy ? null : () => _go(_step - 1))), const SizedBox(width: 12)],
                Expanded(child: _step == _titles.length - 1 ? ErgoButton('Publish workspace', loading: _busy, onPressed: _publish) : ErgoButton('Continue', onPressed: _next)),
              ]),
            ]),
          )),
        ),
      ]),
    );
  }

  Widget _scroll(List<Widget> children) => SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));

  Widget _timeBox(String l, TimeOfDay t, VoidCallback onTap) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.toUpperCase(), style: labelStyle(context)), const SizedBox(height: 8),
        GestureDetector(onTap: onTap, child: Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: context.ergo.surface2, borderRadius: BorderRadius.circular(Rd.input), border: Border.all(color: context.ergo.border)), child: Text(_show(t), style: tabular(const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))))),
      ]);

  Widget _capCard(int i) {
    final c = context.ergo;
    final k = _caps[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text('CAPACITY ${i + 1}', style: labelStyle(context)), const Spacer(), if (_caps.length > 1) GestureDetector(onTap: () => setState(() { _caps.removeAt(i).dispose(); }), child: Icon(Icons.close_rounded, size: 18, color: c.muted))]),
        const SizedBox(height: 12),
        ErgoField(label: 'Name', controller: k.name, hint: 'Dedicated Desk'), const SizedBox(height: 12),
        ErgoField(label: 'Description', controller: k.desc), const SizedBox(height: 12),
        ErgoField(label: 'Available seats', controller: k.count, keyboard: TextInputType.number), const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickSeatImage(k),
          child: Container(
            height: 110, width: double.infinity, clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
            child: k.image == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, color: c.accent), const SizedBox(height: 4), Text('Add seat photo', style: TextStyle(color: c.textSecondary, fontSize: 12))])
                : Image.file(File(k.image!), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ErgoField(label: '₹ / hour', controller: k.hr, keyboard: TextInputType.number)), const SizedBox(width: 8),
          Expanded(child: ErgoField(label: '₹ / day', controller: k.day, keyboard: TextInputType.number)), const SizedBox(width: 8),
          Expanded(child: ErgoField(label: '₹ / month', controller: k.mo, keyboard: TextInputType.number)),
        ]),
      ]),
    );
  }

  Widget _photo(String label, String? path, VoidCallback onTap) {
    final c = context.ergo;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: labelStyle(context)), const SizedBox(height: 8),
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120, width: double.infinity, clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
          child: path == null
              ? Stack(alignment: Alignment.center, children: [const DotMatrix(spacing: 12), Icon(Icons.add_photo_alternate_outlined, color: c.accent)])
              : Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text('Image selected', style: TextStyle(color: c.textSecondary)))),
        ),
      ),
    ]);
  }

  Widget _sum(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Text(k.toUpperCase(), style: labelStyle(context))), Expanded(child: Text(v.isEmpty ? '—' : v, style: const TextStyle(fontWeight: FontWeight.w600)))]),
      );
}

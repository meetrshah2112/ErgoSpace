import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ergo_widgets.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/models.dart';

class WorkspaceDetailsScreen extends ConsumerWidget {
  final int id;
  final String heroSection;
  const WorkspaceDetailsScreen({super.key, required this.id, required this.heroSection});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(workspaceDetailProvider(id));
    return Scaffold(
      body: res.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SafeArea(child: Column(children: [Align(alignment: Alignment.centerLeft, child: BackButton(onPressed: () => context.pop())), Expanded(child: ErrorView(e, onRetry: () => ref.invalidate(workspaceDetailProvider(id))))])),
        data: (w) => _Body(w: w, heroSection: heroSection),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final Workspace w;
  final String heroSection;
  const _Body({required this.w, required this.heroSection});
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  static const _tabs = [
    ('Book a seat', Icons.event_seat_outlined),
    ('Gallery', Icons.photo_library_outlined),
    ('Reviews', Icons.star_outline_rounded),
    ('Location', Icons.place_outlined),
    ('About us', Icons.info_outline_rounded),
  ];
  static const double _heroHeight = 360;
  int _page = 0, _tab = 0;
  bool _allAmenities = false;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _review() => showModalBottomSheet(
        context: context, isScrollControlled: true,
        builder: (_) => _ReviewSheet(workspaceId: widget.w.id, onDone: () => ref.invalidate(workspaceDetailProvider(widget.w.id))),
      );

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) toast(context, 'Could not open that link.');
  }

  bool? get _openNow {
    final w = widget.w;
    if (w.startTime == null || w.endTime == null) return null;
    int m(String t) { final p = t.split(':'); return (int.tryParse(p[0]) ?? 0) * 60 + (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0); }
    final n = DateTime.now();
    final now = n.hour * 60 + n.minute;
    return now >= m(w.startTime!) && now < m(w.endTime!);
  }

  void _goAbout() {
    setState(() => _tab = 4);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      _scroll.animateTo(max < 330 ? max : 330.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    final c = context.ergo;
    return Scaffold(
      backgroundColor: c.bg,
      bottomNavigationBar: _tab == 2
          ? Container(
              decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.border))),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: SafeArea(top: false, minimum: const EdgeInsets.only(bottom: 12), child: ErgoButton('Write a review', icon: Icons.edit_outlined, onPressed: _review)),
            )
          : null,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(child: _hero(w)),
          SliverToBoxAdapter(child: _intro(w)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(topInset: MediaQuery.of(context).padding.top, bg: c.bg, border: c.border, builder: _tabBar),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(key: ValueKey(_tab), child: [_seats, _gallery, _reviews, _location, _about][_tab](w)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ───────────────────────── Hero ─────────────────────────

  Widget _hero(Workspace w) {
    final c = context.ergo;
    final g = w.gallery;
    final avg = w.avgRating;
    final n = w.reviewTotal;
    return SizedBox(
      height: _heroHeight,
      child: Stack(children: [
        Positioned.fill(child: PageView.builder(
          itemCount: g.isEmpty ? 1 : g.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final img = ErgoImage(g.isEmpty ? null : g[i]);
            return i == 0 ? Hero(tag: 'ws-${widget.heroSection}-${w.id}', child: img) : img;
          },
        )),
        Positioned(top: 0, left: 0, right: 0, height: 130, child: IgnorePointer(child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(.55), Colors.transparent])),
        ))),
        Positioned(bottom: 0, left: 0, right: 0, height: 240, child: IgnorePointer(child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.bg.withOpacity(0), c.bg.withOpacity(.85), c.bg], stops: const [0, .65, 1])),
        ))),
        Positioned(top: 0, left: 0, child: SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: _roundBack()))),
        if (g.length > 1)
          Positioned(top: 0, right: 0, child: SafeArea(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: Colors.black.withOpacity(.5), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.photo_library_outlined, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text('${_page + 1} / ${g.length}', style: tabular(const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
              ]),
            ),
          ))),
        Positioned(left: 24, right: 24, bottom: 8, child: IgnorePointer(child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(width: 18, height: 1.5, color: c.accent), const SizedBox(width: 8),
              Flexible(child: Text(w.type.isEmpty ? 'WORKSPACE' : w.type.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.accent, fontSize: 11, letterSpacing: 2.4, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 10),
            Text(w.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: serif(32, height: 1.08)),
          ])),
          const SizedBox(width: 16),
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: c.surface.withOpacity(.92), borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
            child: avg == null
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome_rounded, size: 18, color: c.accent), const SizedBox(height: 4),
                    Text('NEW', style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: c.textSecondary)),
                  ])
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded, size: 18, color: c.accent), const SizedBox(width: 4),
                      Text(avg.toStringAsFixed(1), style: tabular(const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                    ]),
                    const SizedBox(height: 2),
                    Text('$n review${n == 1 ? '' : 's'}', style: TextStyle(fontSize: 11, color: c.muted)),
                  ]),
          ),
        ]))),
      ]),
    );
  }

  Widget _roundBack({double size = 42}) {
    final c = context.ergo;
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(width: size, height: size, decoration: BoxDecoration(color: c.bg.withOpacity(.8), shape: BoxShape.circle, border: Border.all(color: c.border)), child: Icon(Icons.arrow_back_rounded, size: size * .5, color: c.text)),
    );
  }

  // ───────────────────────── Intro (location, description, key facts) ─────────────────────────

  Widget _intro(Workspace w) {
    final c = context.ergo;
    final open = _openNow;
    final loc = [w.address, w.city].where((e) => e.isNotEmpty).join(', ');
    final long = w.description.length > 130;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.place_outlined, size: 16, color: c.muted), const SizedBox(width: 6),
          Expanded(child: Text(loc.isEmpty ? 'Location on request' : loc, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 13))),
          if (open != null) ...[const SizedBox(width: 10), _status(open)],
        ]),
        if (w.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(w.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, height: 1.6, fontSize: 14)),
          if (long)
            GestureDetector(
              onTap: _goAbout,
              child: Padding(padding: const EdgeInsets.only(top: 6), child: Text('Read more', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 13))),
            ),
        ],
        const SizedBox(height: 20),
        _strip(w),
      ]),
    );
  }

  Widget _status(bool open) {
    final c = context.ergo;
    final col = open ? c.accent : c.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: col.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: col, shape: BoxShape.circle)), const SizedBox(width: 6),
        Text(open ? 'Open now' : 'Closed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: col)),
      ]),
    );
  }

  Widget _strip(Workspace w) {
    final c = context.ergo;
    final seats = w.capacities.fold<int>(0, (a, e) => a + (e.capacity ?? 0));
    final nOpt = w.capacities.length;
    const valueStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);
    final cells = <(String, Widget)>[
      if (w.startTime != null && w.endTime != null) ('HOURS', Text('${_tc(w.startTime!)} – ${_tc(w.endTime!)}', style: tabular(valueStyle))),
      if (w.fromPrice != null) ('STARTING AT', Price(w.fromPrice!.$1, per: w.fromPrice!.$2, size: 17)),
      if (nOpt > 0) ('SEATING', Text(seats > 0 ? '$seats seat${seats == 1 ? '' : 's'}' : '$nOpt option${nOpt == 1 ? '' : 's'}', style: tabular(valueStyle))),
    ];
    if (cells.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border)),
      child: Row(children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) Container(width: 1, height: 30, color: c.border),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(cells[i].$1, style: labelStyle(context).copyWith(fontSize: 10)),
              const SizedBox(height: 6),
              FittedBox(fit: BoxFit.scaleDown, child: cells[i].$2),
            ]),
          )),
        ],
      ]),
    );
  }

  // ───────────────────────── Tabs ─────────────────────────

  Widget _tabBar(bool pinned) {
    final c = context.ergo;
    return Row(children: [
      if (pinned) Padding(padding: const EdgeInsets.only(left: 16), child: _roundBack(size: 38)),
      Expanded(child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: pinned ? 10 : 24, vertical: 6),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => setState(() => _tab = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _tab == i ? c.accent : c.surface2, borderRadius: BorderRadius.circular(24), border: Border.all(color: _tab == i ? c.accent : c.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_tabs[i].$2, size: 17, color: _tab == i ? c.onAccent : c.textSecondary), const SizedBox(width: 8),
              Text(_tabs[i].$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _tab == i ? c.onAccent : c.textSecondary)),
            ]),
          ),
        ),
      )),
    ]);
  }

  Widget _pane(List<Widget> children) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text(msg, style: TextStyle(color: context.ergo.textSecondary))),
      );

  // ───────────────────────── Seats ─────────────────────────

  Widget _seats(Workspace w) {
    final c = context.ergo;
    if (w.capacities.isEmpty) return _empty('No seats available yet.');
    return _pane([
      Text('Choose your seat', style: serif(22)),
      const SizedBox(height: 4),
      Text('Tap a seat to continue booking', style: TextStyle(color: c.textSecondary, fontSize: 13)),
      const SizedBox(height: 16),
      for (final cap in w.capacities) _SeatTile(cap: cap, onTap: () => context.push('/customer/book/${w.id}?seat=${cap.id}')),
    ]);
  }

  // ───────────────────────── Gallery ─────────────────────────

  Widget _gallery(Workspace w) {
    final g = w.gallery;
    if (g.isEmpty) return _empty('No photos uploaded yet.');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: g.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(children: [
              Positioned.fill(child: InteractiveViewer(child: ErgoImage(g[i], fit: BoxFit.contain))),
              Positioned(top: 0, right: 0, child: SafeArea(child: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)))),
            ]),
          ),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(16), child: ErgoImage(g[i])),
      ),
    );
  }

  // ───────────────────────── Reviews ─────────────────────────

  Widget _reviews(Workspace w) {
    final c = context.ergo;
    final avg = w.avgRating;
    final n = w.reviewTotal;
    return _pane([
      if (avg != null) Row(children: [
        Text(avg.toStringAsFixed(1), style: tabular(const TextStyle(fontSize: 34, fontWeight: FontWeight.w800))), const SizedBox(width: 8),
        Icon(Icons.star_rounded, color: c.accent), const SizedBox(width: 8),
        Text('$n review${n == 1 ? '' : 's'}', style: TextStyle(color: c.textSecondary)),
      ]),
      if (avg != null) const SizedBox(height: 16),
      if (w.reviews.isEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text('No reviews yet. Be the first to share your experience.', style: TextStyle(color: c.textSecondary)))
      else for (final r in w.reviews) _ReviewTile(r),
    ]);
  }

  // ───────────────────────── Location ─────────────────────────

  Widget _location(Workspace w) {
    final c = context.ergo;
    Widget row(IconData i, String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, size: 18, color: c.muted), const SizedBox(width: 10), Expanded(child: Text(t, style: TextStyle(color: c.textSecondary, height: 1.4)))]));
    return _pane([
      const SectionHeader('Address'), const SizedBox(height: 12),
      row(Icons.place_outlined, [w.address, w.city].where((e) => e.isNotEmpty).join(', ')),
      if (w.distance != null) row(Icons.near_me_outlined, '${w.distance!.toStringAsFixed(1)} km from you'),
      if (w.lat != null && w.lon != null) ErgoButton('Get directions', icon: Icons.directions_rounded, onPressed: () => _open('https://www.google.com/maps/dir/?api=1&destination=${w.lat},${w.lon}')),
    ]);
  }

  // ───────────────────────── About (decongested) ─────────────────────────

  Widget _title(String t, {String? trailing}) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Text(t, style: serif(21))),
        if (trailing != null) Text(trailing, style: TextStyle(color: context.ergo.muted, fontSize: 12)),
      ]);

  Widget _about(Workspace w) {
    final c = context.ergo;

    // 1) Story
    final story = <Widget>[
      _title('About us'), const SizedBox(height: 12),
      Text(
        w.description.isNotEmpty ? w.description : 'The host has not added a description yet.',
        style: TextStyle(color: c.textSecondary, height: 1.7, fontSize: 14.5),
      ),
    ];

    // 2) At a glance
    final seats = w.capacities.fold<int>(0, (a, e) => a + (e.capacity ?? 0));
    final glance = <(IconData, String, String)>[
      if (w.startTime != null && w.endTime != null) (Icons.schedule_rounded, 'OPEN HOURS', '${_t(w.startTime!)} – ${_t(w.endTime!)}'),
      if (w.capacities.isNotEmpty) (Icons.event_seat_outlined, 'SEATING', seats > 0 ? '$seats seat${seats == 1 ? '' : 's'} across ${w.capacities.length} type${w.capacities.length == 1 ? '' : 's'}' : '${w.capacities.length} seat type${w.capacities.length == 1 ? '' : 's'}'),
      if (w.city.isNotEmpty) (Icons.place_outlined, 'LOCATION', w.city),
    ];

    // 3) Amenities
    const previewCount = 6;
    final am = w.amenities;
    final shown = _allAmenities ? am : am.take(previewCount).toList();

    // 4) Host
    final hasHost = w.ownerName.isNotEmpty || w.ownerEmail.isNotEmpty || w.insta != null || w.facebook != null;
    final btns = <Widget>[
      if (w.ownerEmail.isNotEmpty) _ContactBtn(Icons.mail_outline_rounded, 'Email', () => _open('mailto:${w.ownerEmail}?subject=${Uri.encodeComponent('Enquiry about ${w.name}')}')),
      if (w.insta != null) _ContactBtn(Icons.camera_alt_outlined, 'Instagram', () => _open(w.insta!)),
      if (w.facebook != null) _ContactBtn(Icons.thumb_up_alt_outlined, 'Facebook', () => _open(w.facebook!)),
    ];
    final hostName = w.ownerName.isNotEmpty ? w.ownerName : w.name;

    return _pane([
      ...story,
      if (glance.isNotEmpty) ...[
        const SizedBox(height: 28),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border)),
          child: Column(children: [
            for (var i = 0; i < glance.length; i++) ...[
              if (i > 0) Divider(height: 1, color: c.border),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(13)), child: Icon(glance[i].$1, size: 19, color: c.accent)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(glance[i].$2, style: labelStyle(context).copyWith(fontSize: 10)),
                    const SizedBox(height: 3),
                    Text(glance[i].$3, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ])),
                ]),
              ),
            ],
          ]),
        ),
      ],
      if (am.isNotEmpty) ...[
        const SizedBox(height: 32),
        _title('Amenities', trailing: '${am.length} included'),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (ctx, bc) {
          final cw = (bc.maxWidth - 10) / 2;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final a in shown) SizedBox(width: cw, child: _AmenityTile(a.name)),
          ]);
        }),
        if (am.length > previewCount)
          GestureDetector(
            onTap: () => setState(() => _allAmenities = !_allAmenities),
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Center(child: Text(_allAmenities ? 'Show less' : 'Show all ${am.length}', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 13))),
            ),
          ),
      ],
      if (hasHost) ...[
        const SizedBox(height: 32),
        _title('Your host'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: c.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(width: 50, height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                  child: Text(hostName.substring(0, 1).toUpperCase(), style: serif(20, weight: FontWeight.w700, color: c.onAccent))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('HOSTED BY', style: labelStyle(context).copyWith(fontSize: 10)),
                const SizedBox(height: 3),
                Text(hostName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (w.ownerEmail.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(w.ownerEmail, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12))),
              ])),
            ]),
            if (btns.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(children: [
                for (var i = 0; i < btns.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: btns[i]),
                ],
              ]),
            ],
          ]),
        ),
      ],
    ]);
  }

  // ───────────────────────── Time helpers ─────────────────────────

  String _t(String s) {
    final p = s.split(':');
    if (p.length < 2) return s;
    final h = int.tryParse(p[0]) ?? 0;
    return '${h % 12 == 0 ? 12 : h % 12}:${p[1]} ${h >= 12 ? 'PM' : 'AM'}';
  }

  /// Compact: 9:00 → "9 AM", 18:30 → "6:30 PM".
  String _tc(String s) {
    final p = s.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
    final hh = h % 12 == 0 ? 12 : h % 12;
    final mm = m == 0 ? '' : ':${m.toString().padLeft(2, '0')}';
    return '$hh$mm ${h >= 12 ? 'PM' : 'AM'}';
  }
}

// ───────────────────────── Pinned tab bar ─────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final double topInset;
  final Color bg, border;
  final Widget Function(bool pinned) builder;
  _TabBarDelegate({required this.topInset, required this.bg, required this.border, required this.builder});

  static const double _row = 56;
  @override
  double get minExtent => _row + topInset;
  @override
  double get maxExtent => _row + topInset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(
        decoration: BoxDecoration(color: bg, border: overlapsContent ? Border(bottom: BorderSide(color: border)) : null),
        alignment: Alignment.bottomCenter,
        child: SizedBox(height: _row, child: builder(overlapsContent)),
      );

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => true;
}

// ───────────────────────── Seat card ─────────────────────────

class _SeatTile extends StatelessWidget {
  final Capacity cap;
  final VoidCallback onTap;
  const _SeatTile({required this.cap, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final rates = <(String, double)>[
      if (cap.perHour != null) ('PER HOUR', cap.perHour!),
      if (cap.perDay != null) ('PER DAY', cap.perDay!),
      if (cap.perMonth != null) ('PER MONTH', cap.perMonth!),
    ];
    final n = cap.capacity;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(26), border: Border.all(color: c.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 168,
            child: Stack(fit: StackFit.expand, children: [
              ErgoImage(cap.image),
              if (n != null)
                Positioned(top: 12, left: 12, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(.55), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.event_seat_rounded, size: 14, color: Colors.white), const SizedBox(width: 6),
                    Text('$n seat${n == 1 ? '' : 's'}', style: tabular(const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                  ]),
                )),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cap.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: serif(19)),
                if (cap.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(cap.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4))),
              ])),
              const SizedBox(width: 12),
              Container(width: 42, height: 42, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle), child: Icon(Icons.arrow_forward_rounded, size: 20, color: c.onAccent)),
            ]),
          ),
          if (rates.isNotEmpty) ...[
            Divider(height: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(children: [
                for (final r in rates)
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.$1, style: labelStyle(context).copyWith(fontSize: 10)),
                    const SizedBox(height: 4),
                    FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Price(r.$2, size: 17)),
                  ])),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

// ───────────────────────── About helpers ─────────────────────────

IconData _amenityIcon(String name) {
  final n = name.toLowerCase();
  bool has(List<String> k) => k.any(n.contains);
  if (has(['wifi', 'wi-fi', 'internet'])) return Icons.wifi_rounded;
  if (has(['coffee', 'tea', 'cafe', 'café'])) return Icons.coffee_rounded;
  if (has(['ac', 'air', 'cool'])) return Icons.ac_unit_rounded;
  if (has(['park'])) return Icons.local_parking_rounded;
  if (has(['power', 'charg', 'plug', 'socket'])) return Icons.power_rounded;
  if (has(['print', 'scan'])) return Icons.print_rounded;
  if (has(['meeting', 'conference', 'board'])) return Icons.meeting_room_rounded;
  if (has(['cctv', 'secur', 'camera'])) return Icons.videocam_rounded;
  if (has(['food', 'lunch', 'snack', 'pantry', 'kitchen'])) return Icons.restaurant_rounded;
  if (has(['water'])) return Icons.water_drop_rounded;
  if (has(['lift', 'elevator'])) return Icons.elevator_rounded;
  if (has(['access', 'wheel'])) return Icons.accessible_rounded;
  return Icons.check_circle_outline_rounded;
}

class _AmenityTile extends StatelessWidget {
  final String name;
  const _AmenityTile(this.name);
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
      child: Row(children: [
        Icon(_amenityIcon(name), size: 18, color: c.accent), const SizedBox(width: 10),
        Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactBtn(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: c.text), const SizedBox(width: 6),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
        ]),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review r;
  const _ReviewTile(this.r);
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(r.by, style: const TextStyle(fontWeight: FontWeight.w700))),
          Icon(Icons.star_rounded, size: 16, color: c.accent), const SizedBox(width: 4),
          Text(r.rating.toStringAsFixed(r.rating % 1 == 0 ? 0 : 1), style: tabular(const TextStyle(fontWeight: FontWeight.w700))),
        ]),
        if (r.text.isNotEmpty) ...[const SizedBox(height: 6), Text(r.text, style: TextStyle(color: c.textSecondary, height: 1.45))],
      ]),
    );
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  final int workspaceId;
  final VoidCallback onDone;
  const _ReviewSheet({required this.workspaceId, required this.onDone});
  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  int _rating = 0;
  final _text = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() { _text.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_busy) return;
    if (_rating == 0) { setState(() => _error = 'Choose a rating first.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await ref.read(workspaceRepoProvider).review(widget.workspaceId, _rating, _text.text.trim());
      widget.onDone();
      if (mounted) { Navigator.pop(context); toast(context, 'Thanks — your review was submitted.'); }
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = ApiException.from(e).message; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How was your visit?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(children: [
          for (var i = 1; i <= 5; i++)
            GestureDetector(
              onTap: () => setState(() => _rating = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(right: 10), width: 48, height: 48, alignment: Alignment.center,
                decoration: BoxDecoration(color: i <= _rating ? c.accent : c.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
                child: Text('$i', style: tabular(TextStyle(fontWeight: FontWeight.w800, color: i <= _rating ? c.onAccent : c.textSecondary))),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        ErgoField(label: 'Your feedback', controller: _text, maxLines: 4, hint: 'Tell others what stood out'),
        if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: TextStyle(color: c.error))],
        const SizedBox(height: 20),
        ErgoButton('Submit review', loading: _busy, onPressed: _submit),
      ]),
    );
  }
}

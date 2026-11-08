import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/models/models.dart';
import '../theme/app_colors.dart';
import 'ergo_widgets.dart';

/// Premium workspace card. With [expand] = true it fills the height it is given
/// (used in the home carousel); otherwise it sizes to its content (search list).
class WorkspaceCard extends StatelessWidget {
  final Workspace w;
  final double? width;
  final VoidCallback onTap;
  final String section;
  final double imageHeight;
  final bool expand;
  const WorkspaceCard(this.w, {super.key, required this.onTap, this.width, this.section = 'list', this.imageHeight = 200, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final price = w.fromPrice;
    final rating = w.avgRating;
    final extra = w.amenities.length - 3;

    final info = Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: [
        Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: c.text, height: 1.15)),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.place_outlined, size: 14, color: c.accent), const SizedBox(width: 4),
          Expanded(child: Text(w.city.isEmpty ? 'Location on request' : w.city, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 13))),
          if (w.distance != null) Text('${w.distance!.toStringAsFixed(1)} km', style: TextStyle(color: c.accent, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        if (w.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(w.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4)),
        ],
        if (w.amenities.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final a in w.amenities.take(3)) _chip(context, a.name),
            if (extra > 0) _chip(context, '+$extra'),
          ]),
        ],
        if (expand) const Spacer() else const SizedBox(height: 14),
        Container(height: 1, color: c.border),
        const SizedBox(height: 12),
        Row(children: [
          if (price != null)
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('FROM', style: TextStyle(fontSize: 9, letterSpacing: 1.6, color: c.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Price(price.$1, per: price.$2, size: 20),
            ])
          else
            Text('Pricing on request', style: TextStyle(color: c.muted, fontSize: 12)),
          const Spacer(),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
            child: Icon(Icons.arrow_outward_rounded, size: 20, color: c.onAccent),
          ),
        ]),
      ]),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.surface, c.surface2]),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: c.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: [
          Stack(children: [
            SizedBox(height: imageHeight, width: double.infinity, child: Hero(tag: 'ws-$section-${w.id}', child: ErgoImage(w.cover))),
            Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(.25), Colors.transparent, Colors.black.withOpacity(.55)], stops: const [0, .5, 1]),
            )))),
            Positioned(left: 14, top: 14, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.black.withOpacity(.55), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
              child: Text(w.type.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: Colors.white)),
            )),
            Positioned(right: 14, top: 14, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.black.withOpacity(.55), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, size: 14, color: c.accent), const SizedBox(width: 4),
                Text(rating == null ? 'New' : '${rating.toStringAsFixed(1)} (${w.reviewTotal})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            )),
          ]),
          if (expand) Expanded(child: info) else info,
        ]),
      ),
    );
  }

  Widget _chip(BuildContext context, String t) {
    final c = context.ergo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border)),
      child: Text(t, maxLines: 1, style: TextStyle(fontSize: 11, color: c.textSecondary, fontWeight: FontWeight.w600)),
    );
  }
}

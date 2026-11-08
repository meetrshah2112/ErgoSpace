import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';
import '../network/api_exceptions.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Dot-matrix texture – the ErgoSpace signature detail.
class DotMatrix extends StatelessWidget {
  final double spacing, radius;
  final Color? color;
  final bool fadeDown;
  const DotMatrix({super.key, this.spacing = 14, this.radius = 1.4, this.color, this.fadeDown = true});
  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DotPainter(color ?? context.ergo.muted, context.ergo.accent, spacing, radius, fadeDown),
        size: Size.infinite,
      );
}

class _DotPainter extends CustomPainter {
  final Color base, accent;
  final double spacing, radius;
  final bool fade;
  _DotPainter(this.base, this.accent, this.spacing, this.radius, this.fade);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final cols = (size.width / spacing).floor(), rows = (size.height / spacing).floor();
    for (var i = 0; i <= cols; i++) {
      for (var j = 0; j <= rows; j++) {
        final o = fade ? (1 - j / (rows + 1)) * 0.55 : 0.35;
        final hit = (i * 7 + j * 13) % 41 == 0;
        p.color = (hit ? accent : base).withOpacity(hit ? 0.95 : o);
        canvas.drawCircle(Offset(i * spacing + spacing / 2, j * spacing + spacing / 2), hit ? radius * 1.5 : radius, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPainter o) => o.base != base || o.accent != accent;
}

class Wordmark extends StatelessWidget {
  final double size;
  const Wordmark({super.key, this.size = 18});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Image.asset(
        'assets/images/logo.png',
        width: size * 1.3, height: size * 1.3, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(width: size * .5, height: size * .5, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
      ),
      SizedBox(width: size * .4),
      Text('ERGOSPACE', style: TextStyle(fontSize: size * .8, fontWeight: FontWeight.w800, letterSpacing: 2.4, color: c.text)),
    ]);
  }
}

class ErgoButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading, secondary, danger;
  final IconData? icon;
  const ErgoButton(this.label, {super.key, this.onPressed, this.loading = false, this.secondary = false, this.danger = false, this.icon});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final bg = danger ? c.error : (secondary ? c.surface2 : c.accent);
    final fg = danger ? Colors.white : (secondary ? c.text : c.onAccent);
    final enabled = onPressed != null && !loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: onPressed == null ? .45 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(Rd.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(Rd.button),
          onTap: enabled ? () { HapticFeedback.lightImpact(); onPressed!(); } : null,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: secondary ? BoxDecoration(borderRadius: BorderRadius.circular(Rd.button), border: Border.all(color: c.border)) : null,
            child: loading
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
                    Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
                  ]),
          ),
        ),
      ),
    );
  }
}

class ErgoField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? hint, errorText;
  final bool obscure;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  const ErgoField({super.key, required this.label, this.controller, this.hint, this.errorText, this.obscure = false, this.keyboard, this.validator, this.maxLines = 1, this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: labelStyle(context)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          validator: validator,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(hintText: hint, errorText: errorText),
        ),
      ]);
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: context.ergo.accent, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        if (trailing != null) Text(trailing!, style: TextStyle(color: context.ergo.muted, fontSize: 12)),
      ]);
}

class Price extends StatelessWidget {
  final num amount;
  final String? per;
  final double size;
  const Price(this.amount, {super.key, this.per, this.size = 22});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Text.rich(TextSpan(children: [
      TextSpan(text: '₹', style: TextStyle(fontSize: size * .62, color: c.textSecondary, fontWeight: FontWeight.w600)),
      TextSpan(text: money(amount), style: tabular(TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: c.text))),
      if (per != null) TextSpan(text: ' / $per', style: TextStyle(fontSize: size * .55, color: c.muted)),
    ]));
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color? color;
  final bool filled;
  const Tag(this.text, {super.key, this.color, this.filled = false});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final col = color ?? c.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? col.withOpacity(.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: filled ? Colors.transparent : c.border),
      ),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: col)),
    );
  }
}

class ErgoImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  const ErgoImage(this.url, {super.key, this.fit = BoxFit.cover});
  Widget _fallback(BuildContext c) => Container(
        color: c.ergo.surface2,
        child: Stack(fit: StackFit.expand, children: [
          const DotMatrix(spacing: 12),
          Center(child: Icon(Icons.apartment_rounded, color: c.ergo.muted, size: 28)),
        ]),
      );
  @override
  Widget build(BuildContext context) {
    final u = ApiConfig.media(url);
    if (u == null) return _fallback(context);
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => Container(color: context.ergo.surface2),
      errorWidget: (_, __, ___) => _fallback(context),
    );
  }
}

class Skeleton extends StatefulWidget {
  final double? width, height;
  final double radius;
  const Skeleton({super.key, this.width, this.height, this.radius = 16});
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: widget.width, height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(context.ergo.surface, context.ergo.elevated, _c.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final bool compact;
  const ErrorView(this.error, {super.key, this.onRetry, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    final msg = ApiException.from(error).message;
    final body = Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.cloud_off_rounded, color: c.muted, size: 34),
      const SizedBox(height: 12),
      const Text('Something interrupted this', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(msg, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.4)),
      if (onRetry != null) ...[const SizedBox(height: 16), SizedBox(width: 160, child: ErgoButton('Try again', secondary: true, onPressed: onRetry))],
    ]);
    return Center(child: Padding(padding: EdgeInsets.all(compact ? 16 : 32), child: body));
  }
}

class EmptyView extends StatelessWidget {
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  const EmptyView({super.key, required this.title, required this.message, this.actionLabel, this.onAction, this.icon = Icons.grid_view_rounded});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 120, height: 80, child: Stack(alignment: Alignment.center, children: [const DotMatrix(spacing: 10, fadeDown: false), Icon(icon, color: c.accent, size: 30)])),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.textSecondary, height: 1.45)),
          if (actionLabel != null) ...[const SizedBox(height: 20), SizedBox(width: 220, child: ErgoButton(actionLabel!, onPressed: onAction))],
        ]),
      ),
    );
  }
}

class ErgoNavItem {
  final IconData icon;
  final String label;
  const ErgoNavItem(this.icon, this.label);
}

class ErgoNavBar extends StatelessWidget {
  final List<ErgoNavItem> items;
  final int index;
  final ValueChanged<int> onTap;
  const ErgoNavBar({super.key, required this.items, required this.index, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Container(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () { HapticFeedback.selectionClick(); onTap(i); },
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
                      width: i == index ? 20 : 4, height: 3,
                      decoration: BoxDecoration(color: i == index ? c.accent : Colors.transparent, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 8),
                    Icon(items[i].icon, size: 22, color: i == index ? c.text : c.muted),
                    const SizedBox(height: 3),
                    Text(items[i].label, style: TextStyle(fontSize: 11, fontWeight: i == index ? FontWeight.w700 : FontWeight.w500, color: i == index ? c.text : c.muted)),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Segmented selector used for filters/modes.
class Segmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T> onChanged;
  const Segmented({super.key, required this.options, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final c = context.ergo;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.border)),
      child: Row(children: [
        for (final o in options)
          Expanded(
            child: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); onChanged(o.$1); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: o.$1 == value ? c.accent : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Text(o.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: o.$1 == value ? c.onAccent : c.textSecondary)),
              ),
            ),
          ),
      ]),
    );
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

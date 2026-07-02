import 'package:flutter/material.dart';

const _kGold  = Color(0xFFEF9F27);
const _kText1 = Color(0xFF0D1B2A);
const _kText2 = Color(0xFF6B7280);

class RateUsCard extends StatefulWidget {
  const RateUsCard({super.key});
  @override
  State<RateUsCard> createState() => _RateUsCardState();
}

class _RateUsCardState extends State<RateUsCard> {
  int _rating = 0;
  bool _submitted = false;
  int _hovered = 0;

  void _submit(int stars) {
    setState(() {
      _rating = stars;
      _submitted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stars >= 4
                  ? 'Awesome! Thanks for the $stars-star rating.'
                  : 'Thank you for your feedback!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0F6E56),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      elevation: 6,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _submitted ? 'Thank You! 🎉' : 'Enjoying the App?',
                    key: ValueKey(_submitted),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kText1,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _submitted
                      ? 'Your feedback means a lot to us.'
                      : 'Tap a star to rate your experience',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _kText2,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Stars or heart
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _submitted
                ? Container(
                    key: const ValueKey('heart'),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_rounded, size: 26, color: _kGold),
                  )
                : Row(
                    key: const ValueKey('stars'),
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      final sel = _hovered >= idx || _rating >= idx;
                      return GestureDetector(
                        onTapDown: (_) => setState(() => _hovered = idx),
                        onTapUp: (_) => _submit(idx),
                        onTapCancel: () => setState(() => _hovered = 0),
                        child: AnimatedScale(
                          scale: sel ? 1.25 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutBack,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: Icon(
                              sel ? Icons.star_rounded : Icons.star_border_rounded,
                              color: sel ? _kGold : const Color(0xFFCBD5E1),
                              size: 28, // Slightly larger stars
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }
}


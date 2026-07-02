import 'package:flutter/material.dart';
import '../screens/quick_actions/quick_support.dart';

class FloatingAiBubble extends StatefulWidget {
  const FloatingAiBubble({super.key});

  @override
  State<FloatingAiBubble> createState() => _FloatingAiBubbleState();
}

class _FloatingAiBubbleState extends State<FloatingAiBubble> with TickerProviderStateMixin {
  Offset? _position;
  late AnimationController _pulseController;
  late AnimationController _textController;

  static const _primary = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Fade in text after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _textController.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_position == null) {
      final size = MediaQuery.of(context).size;
      // Default position: Bottom-Right, above the dock
      _position = Offset(size.width - 76, size.height - 180);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_position == null) return const SizedBox.shrink();
    final size = MediaQuery.of(context).size;
    
    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: Draggable(
        feedback: _buildBubble(isFeedback: true),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          setState(() {
            double x = details.offset.dx.clamp(20.0, size.width - 80.0);
            double y = details.offset.dy.clamp(100.0, size.height - 180.0);
            _position = Offset(x, y);
          });
        },
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuickSupportScreen()),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerRight,
            children: [
              // ── Call to Action Text ──
              Positioned(
                right: 60,
                child: FadeTransition(
                  opacity: _textController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutBack)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: _primary.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.chat_bubble_outline_rounded, size: 14, color: _primary),
                          SizedBox(width: 8),
                          Text(
                            "Ask Question",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // ── Pulse / AI Bubble ──
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.08).animate(
                  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: _buildBubble(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble({bool isFeedback = false}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(isFeedback ? 0.5 : 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

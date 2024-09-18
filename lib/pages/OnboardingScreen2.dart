import 'package:flutter/material.dart';
import 'dart:math';

class DevPage extends StatefulWidget {
  @override
  _OnboardingScreen2State createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<DevPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // List of avatars data
    final avatars = [
      {'name': 'Fady Gerges', 'image': "devs/fady_gerges.png"},
      {'name': 'Kareem Ahmed', 'image': 'devs/kimo.png'},
      {'name': 'Abdelrahman', 'image': 'devs/khyat.jpg'},
      {'name': 'Kareem Amr', 'image': 'devs/kareem.jpg'},
    ];

    return Scaffold(


      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SafeArea(
                  child: BackButton(
                    color: Colors.white, // Set the color of the back button icon
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            const Text(
              'Developers',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 200),
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: List.generate(4, (index) {
                    final angle = 2 * pi * index / 4;
                    final radius = 100.0;

                    final x = radius * cos(angle);
                    final y = radius * sin(angle);

                    return AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(x, y + _animation.value),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    AssetImage(avatars[index]['image']!),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                avatars[index]['name']!,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DevPage extends StatefulWidget {
  @override
  _OnboardingScreen2State createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<DevPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _leftToRightAnimation;
  late Animation<double> _rightToLeftAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    // Left avatar moves to the right
    _leftToRightAnimation = Tween<double>(begin: 180, end: -90).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Right avatar moves to the left
    _rightToLeftAnimation = Tween<double>(begin: 180, end: -90).animate(
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
      {'name': 'Abdelrahman', 'image': 'devs/khyat.jpg'},
      {'name': 'Kareem Amr', 'image': 'devs/kareem.jpg'},
      {'name': 'Fady Gerges', 'image': "devs/fady_gerges.png"},
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
                    color: Colors.white,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Color(0xFFFFA600),
                  Color(0xFFFBE476),
                  Color(0xFFFFB700),

                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Developers',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // This will be ignored due to the ShaderMask
                ),
              ),
            ),
            const SizedBox(height: 50), // Space for avatars

            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Top avatar (Fady)
                    Positioned(
                      top: 0,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: AssetImage(avatars[2]['image']!),
                            backgroundColor: const Color(0xFFFFD700),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.amber,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            avatars[2]['name']!,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Backend and UI Expert, Passionate About App Design',
                            style: TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Left-down avatar (Abdelrahman) - moves to the right
                    AnimatedBuilder(
                      animation: _leftToRightAnimation,
                      builder: (context, child) {
                        return Positioned(
                          bottom: -120,
                          left: _leftToRightAnimation.value,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: AssetImage(avatars[0]['image']!),
                                backgroundColor: Colors.transparent,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                avatars[0]['name']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Right-down avatar (Kareem Amr) - moves to the left
                    AnimatedBuilder(
                      animation: _rightToLeftAnimation,
                      builder: (context, child) {
                        return Positioned(
                          bottom: -120,
                          right: _rightToLeftAnimation.value,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: AssetImage(avatars[1]['image']!),
                                backgroundColor: Colors.transparent,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                avatars[1]['name']!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'OnboardingScreen1.dart';
import 'OnboardingScreen2.dart';
import 'OnboardingScreen3.dart';

class OnboardingPageView extends StatefulWidget {
  @override
  _OnboardingPageViewState createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends State<OnboardingPageView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              OnboardingScreen1(),
              OnboardingScreen2(),
              OnboardingScreen3(),
            ],
          ),
          Positioned(
            bottom: 100,
            left: MediaQuery.of(context).size.width * 0.5 - 30,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => buildDot(index),
              ),
            ),
          ),
          if (_currentPage < 2)
            Positioned(
              bottom: 20,
              left: 20,
              child: TextButton(
                onPressed: () {
                  _pageController.jumpToPage(2);
                },
                child: Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15)),
                  child: Center(
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_currentPage < 2)
            Positioned(
              bottom: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text('Next'),
              ),
            ),
        ],
      ),
    );
  }

  AnimatedContainer buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Color.fromARGB(255, 36, 68, 64)
            : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

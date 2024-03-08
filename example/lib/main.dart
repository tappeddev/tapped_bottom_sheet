import 'package:flutter/material.dart';
import 'package:tapped_bottom_sheet/scrollable_bottom_sheet.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height - kToolbarHeight;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bottom Sheet Example'),
        ),
        body: Stack(
          children: [
            Positioned.fill(
                child: Container(
              color: Colors.green,
            )),
            Align(
              alignment: Alignment.bottomCenter,
              child: ScrollableBottomSheet(
                snapPoints: [maxHeight / 2],
                initialPosition: maxHeight / 2,
                onSizeChanged: (tween,height) {
                  print(tween);
                },
                maxHeight: maxHeight,
                minHeight: 100,
                builder: (context, scrollController) {
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text('Element $index'),
                      );
                    },
                  );
                },
                borderRadiusTop: 15,
                borderColor: Colors.black,
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

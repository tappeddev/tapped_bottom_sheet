import 'package:flutter/material.dart';
import 'package:tapped_bottom_sheet/scrollable_bottom_sheet.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height - kToolbarHeight - 100;
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
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ScrollableBottomSheet(
                snapPositions: [maxHeight / 2],
                initialPosition: maxHeight / 2,
                maxHeight: maxHeight,
                minHeight: 100,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Horizontal Scroll"),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Container(
                                  color: Colors.red,
                                  width: 100,
                                  child: Text(index.toString()),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          height: 200,
                        ),
                      ],
                    ),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapped_bottom_sheet/scrollable_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ScrollController? _scrollController;
  final _scrollableBSKey = GlobalKey<ScrollableBottomSheetState>();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bottom Sheet Example'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ScrollableBottomSheet(
              key: _scrollableBSKey,
              snapPositions: [maxHeight / 2],
              initialPosition: maxHeight / 2,
              maxHeight: maxHeight,
              minHeight: 100,
              builder: (context, scrollController) {
                _scrollController = scrollController;

                return ListView.builder(
                  controller: scrollController,
                  itemCount: 100,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: ElevatedButton(
                        onPressed: index == 0 ? _open : () {},
                        child: Text('Element $index'),
                      ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToLastElementOfList,
        child: const Icon(Icons.arrow_downward_rounded),
      ),
    );
  }

  Future<void> _open() async {
    await _scrollableBSKey.currentState!.open();
  }

  Future<void> _scrollToLastElementOfList() async {
    if (_scrollController == null || _scrollableBSKey.currentState == null) {
      return;
    }

    unawaited(_scrollableBSKey.currentState!.open());

    final maxScrollExtent = _scrollController!.position.maxScrollExtent;
    await _scrollController?.animateTo(
      maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.bounceIn,
    );
  }
}

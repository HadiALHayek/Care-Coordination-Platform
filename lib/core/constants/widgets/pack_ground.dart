import 'package:flutter/cupertino.dart';

class PackGround extends StatelessWidget {
  final ImageProvider imageProvider;

  const PackGround({super.key,
    required this.imageProvider });

  const PackGround.withDefaultImage({super.key})
      : imageProvider = const AssetImage('assets/log.png');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

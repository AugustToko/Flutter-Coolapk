part of 'package:coolapk_flutter/widget/item_adapter/items/items.dart';

class ImageCarouselCard extends StatelessWidget {
  final Map<String, dynamic> source;
  const ImageCarouselCard({Key key, this.source}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double aspectRatio =
        getImageRatio(source["entities"][0]["pic"] ?? "@0x0.x");
    return MCard(
      padding: const EdgeInsets.all(0),
      child: CarouselSlider.builder(
        aspectRatio: aspectRatio,
        viewportFraction: 1.0,
        autoPlay: true,
        enableInfiniteScroll: source["entities"].length > 1,
        itemCount: source["entities"].length,
        itemBuilder: (final context, final index) => InkWell(
          onTap: () {},
          child: ExtendedImage.network(
            source["entities"][index]["pic"],
            fit: BoxFit.cover,
            shape: BoxShape.rectangle,
            cache: false, // TODO:
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

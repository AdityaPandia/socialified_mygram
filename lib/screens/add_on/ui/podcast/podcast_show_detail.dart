import 'package:cached_network_image/cached_network_image.dart';
import 'package:foap/components/custom_texts.dart';
import 'package:foap/components/top_navigation_bar.dart';
import 'package:foap/controllers/podcast_streaming_controller.dart';
import 'package:foap/helper/common_components.dart';
import 'package:foap/helper/extension.dart';
import 'package:foap/helper/localization_strings.dart';
import 'package:foap/screens/add_on/model/podcast_model.dart';
import 'package:foap/util/app_config_constants.dart';
import 'package:get/get.dart';
import 'package:readmore/readmore.dart' as read_more;
import 'audio_song_player.dart';
import 'package:flutter/material.dart';

class PodcastShowDetail extends StatefulWidget {
  final PodcastShowModel podcastShowModel;

  const PodcastShowDetail({Key? key, required this.podcastShowModel})
      : super(key: key);

  @override
  State<PodcastShowDetail> createState() => _PodcastShowDetailState();
}

class _PodcastShowDetailState extends State<PodcastShowDetail> {
  final PodcastStreamingController _podcastStreamingController = Get.find();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _podcastStreamingController.getPodcastShowsEpisode(
          podcastShowId: widget.podcastShowModel.id);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColorConstants.backgroundColor,
        body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              backNavigationBar(
                  context: context, title: widget.podcastShowModel.name)
                  .tp(50),
              divider(context: context).tP8,
              Expanded(
                child: CustomScrollView(slivers: [
                  SliverList(
                      delegate: SliverChildListDelegate([
                        podcastInfo(),
                        const SizedBox(
                          height: 40,
                        ),
                        Heading6Text(LocalizationString.audios,
                            color: AppColorConstants.themeColor,
                            weight: TextWeight.bold,
                            )
                            .hP16,
                        const SizedBox(
                          height: 20,
                        ),
                        Obx(() => SizedBox(
                          height: _podcastStreamingController
                              .podcastShowEpisodes.length *
                              60,
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            scrollDirection: Axis.vertical,
                            itemCount: _podcastStreamingController
                                .podcastShowEpisodes.length,
                            itemBuilder: (BuildContext context, int index) {
                              return addRecord(index);
                            },
                          ).hP16,
                        )),
                      ]))
                ]),
              )
            ]));
  }

  Widget podcastInfo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 200,
          child: CachedNetworkImage(
            imageUrl: widget.podcastShowModel.image,
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width,
            height: 200,
          )),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
                color: AppColorConstants.themeColor,
                child: Text(widget.podcastShowModel.ageGroup)
                    .setPadding(left: 10, right: 10, top: 5, bottom: 5))
                .round(10),
            const SizedBox(width: 10),
            Container(
                color: AppColorConstants.themeColor,
                child: Text(widget.podcastShowModel.language)
                    .setPadding(left: 10, right: 10, top: 5, bottom: 5))
                .round(10),
          ],
        ),
        Text(widget.podcastShowModel.name,
            style: const TextStyle(fontWeight: FontWeight.bold))
            .setPadding(top: 8, bottom: 4),
        read_more.ReadMoreText(
          widget.podcastShowModel.description,
          trimLines: 2,
          trimMode: read_more.TrimMode.Line,
          colorClickableText: Colors.white,
          trimCollapsedText: LocalizationString.showMore,
          trimExpandedText: '    ${LocalizationString.showLess}',
          moreStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          lessStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ]).setPadding(left: 16, right: 16, top: 15),
    ]);
  }

  Widget addRecord(int index) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(6),
        leading: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: _podcastStreamingController
                  .podcastShowEpisodes[index].imageUrl,
              fit: BoxFit.cover,
              height: 50,
              width: 50,
            ).round(10),
            const Positioned.fill(child: Icon(Icons.play_circle))
          ],
        ),
        title:
        Text(_podcastStreamingController.podcastShowEpisodes[index].name),
        dense: true,
      ),
    ).setPadding(bottom: 5).round(10).ripple(() {
      Get.to(() => AudioSongPlayer(
          songsArray: _podcastStreamingController.podcastShowEpisodes,
          show: widget.podcastShowModel));
    });
  }
}

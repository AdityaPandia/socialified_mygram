import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:foap/components/post_card/reshare_post.dart';
import 'package:foap/components/post_card_controller.dart';
import 'package:foap/components/reply_chat_cells/post_gift_controller.dart';
import 'package:foap/components/post_card/video_widget.dart';
import 'package:foap/controllers/profile/profile_controller.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../controllers/chat_and_call/chat_detail_controller.dart';
import '../../controllers/chat_and_call/select_user_for_chat_controller.dart';
import '../../controllers/clubs/clubs_controller.dart';
import '../../controllers/home/home_controller.dart';
import '../../controllers/post/comments_controller.dart';
import '../../controllers/post/post_controller.dart';
import '../../model/post_gallery.dart';
import '../../model/post_model.dart';
import '../../model/post_search_query.dart';
import '../../screens/chat/select_users.dart';
import '../../screens/club/club_detail.dart';
import '../../screens/competitions/competition_detail_screen.dart';
import '../../screens/dashboard/posts.dart';
import '../../screens/home_feed/comments_screen.dart';
import '../../screens/home_feed/post_media_full_screen.dart';
import '../../screens/live/gifts_list.dart';
import '../../screens/post/edit_post.dart';
import '../../screens/post/liked_by_users.dart';
import '../../screens/post/received_gifts.dart';
import '../../screens/post/view_post_insight.dart';
import '../../screens/profile/my_profile.dart';
import '../../screens/profile/other_user_profile.dart';
import 'club_post_tile.dart';
import 'competition_post_tile.dart';

class PostMediaTile extends StatelessWidget {
  final PostCardController postCardController = Get.find();
  final HomeController homeController = Get.find();
  final bool isSharedPostMedia;

  final PostModel model;

  PostMediaTile(
      {Key? key, required this.model, required this.isSharedPostMedia})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return mediaTile();
  }

  Widget mediaTile() {
    if (model.gallery.length > 1) {
      return SizedBox(
        height: 350,
        child: Stack(
          children: [
            CarouselSlider(
              items: mediaList(isSharedPostMedia),
              options: CarouselOptions(
                aspectRatio: 1,
                enlargeCenterPage: false,
                enableInfiniteScroll: false,
                height: double.infinity,
                viewportFraction: 1,
                onPageChanged: (index, reason) {
                  postCardController.updateGallerySlider(index, model.id);
                },
              ),
            ),
            Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Obx(
                    () {
                      return DotsIndicator(
                        dotsCount: model.gallery.length,
                        position: (postCardController
                                .postScrollIndexMapping[model.id] ??
                            0),
                        decorator: DotsDecorator(
                            activeColor: Theme.of(Get.context!).primaryColor),
                      );
                    },
                  ),
                ))
          ],
        ),
      );
    } else {
      return model.contentType == PostContentType.media
          ? model.gallery.first.isVideoPost == true
              ? videoPostTile(
                  media: model.gallery.first, isReshared: isSharedPostMedia)
              : SizedBox(height: 350, child: photoPostTile(model.gallery.first))
          : model.contentType == PostContentType.competitionAdded ||
                  model.contentType == PostContentType.competitionResultDeclared
              ? CompetitionPostTile(
                  post: model,
                  isResharedPost: isSharedPostMedia,
                )
              : model.contentType == PostContentType.club
                  ? ClubPostTile(
                      post: model,
                      isResharedPost: isSharedPostMedia,
                    )
                  : Container();
    }
  }

  List<Widget> mediaList(bool isReshared) {
    return model.gallery.map((item) {
      if (item.isVideoPost == true) {
        return videoPostTile(media: item, isReshared: isReshared);
      } else {
        return photoPostTile(item);
      }
    }).toList();
  }

  Widget videoPostTile({required PostGallery media, required bool isReshared}) {
    return VisibilityDetector(
      key: Key(media.id.toString()),
      onVisibilityChanged: (visibilityInfo) {
        var visiblePercentage = visibilityInfo.visibleFraction * 100;
        // if (visiblePercentage > 80) {
        homeController.setCurrentVisibleVideo(
            media: media, visibility: visiblePercentage);
        // }
      },
      child: Obx(() => VideoPostTile(
            media: media,
            url: media.filePath,
            isLocalFile: false,
            play: homeController.currentVisibleVideoId.value == media.id,
            width: isReshared
                ? Get.width - ((DesignConstants.horizontalPadding * 3) + 10)
                : Get.width,
            onTapActionHandler: () {},
          )),
    );
  }

  Widget photoPostTile(PostGallery media) {
    return CachedNetworkImage(
      imageUrl: media.filePath,
      fit: BoxFit.cover,
      width: Get.width,
      placeholder: (context, url) => AppUtil.addProgressIndicator(size: 100),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }
}

class PostCard extends StatefulWidget {
  final PostModel model;

  final VoidCallback removePostHandler;
  final VoidCallback blockUserHandler;

  const PostCard({
    Key? key,
    required this.model,
    required this.removePostHandler,
    required this.blockUserHandler,
  }) : super(key: key);

  @override
  PostCardState createState() => PostCardState();
}

class PostCardState extends State<PostCard> {
  final HomeController homeController = Get.find();
  final PostCardController postCardController = Get.find();
  final ChatDetailController chatDetailController = Get.find();
  final SelectUserForChatController selectUserForChatController =
      SelectUserForChatController();
  final ProfileController _profileController = Get.find();
  final FlareControls flareControls = FlareControls();
  final PostGiftController _postGiftController = Get.find();
  final PostController _postController = Get.find();

  TextEditingController commentInputField = TextEditingController();
  final CommentsController _commentsController = CommentsController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      addPostUserInfo().setPadding(
          left: DesignConstants.horizontalPadding,
          right: DesignConstants.horizontalPadding,
          bottom: 16),

      GestureDetector(
          onDoubleTap: () {
            //   widget.model.isLike = !widget.model.isLike;
            postCardController.likeUnlikePost(post: widget.model);
            // widget.likeTapHandler();
            flareControls.play("like");
          },
          onTap: () {},
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.model.postTitle.isNotEmpty)
                    _convertHashtag(widget.model.postTitle).setPadding(
                        left: DesignConstants.horizontalPadding,
                        right: DesignConstants.horizontalPadding,
                        bottom: 25),
                  // if (widget.model.gallery.isNotEmpty)
                  PostMediaTile(
                    model: widget.model,
                    isSharedPostMedia: widget.model.sharedPost != null,
                  ),
                  if (widget.model.isMyPost)
                    Container(
                      color: AppColorConstants.cardColor,
                      height: 50,
                      width: double.infinity,
                      child: BodyLargeText(
                        viewInsightsString.tr,
                        weight: TextWeight.semiBold,
                      ).p16.ripple(() {
                        Get.to(() => ViewPostInsights(post: widget.model));
                      }),
                    )
                ],
              ),
              Obx(() => Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: FlareActor(
                              'assets/like.flr',
                              controller: flareControls,
                              animation: 'idle',
                              color: postCardController.likedPosts
                                          .contains(widget.model) ||
                                      widget.model.isLike
                                  ? Colors.red
                                  : Colors.white,
                            ),
                          ),
                        )),
                  ))
            ],
          )),
      const SizedBox(
        height: 16,
      ),
      commentAndLikeWidget().hp(DesignConstants.horizontalPadding),
      // const SizedBox(
      //   height: 8,
      // ),
      commentsCountWidget().hp(DesignConstants.horizontalPadding),
      postTimeView().hp(DesignConstants.horizontalPadding)
      // if (widget.model.commentsEnabled) buildMessageTextField(),
    ]).vP16;
  }

  Widget postTimeView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // const ThemeIconWidget(
        //   ThemeIcon.clock,
        //   size: 15,
        // ),
        // const SizedBox(width: 5),
        BodyExtraSmallText(widget.model.postTime.tr,
            weight: TextWeight.regular),
      ],
    ).tP8;
  }

  Widget commentsCountWidget() {
    return InkWell(
        onTap: () => openComments(),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          widget.model.totalComment > 0 && widget.model.commentsEnabled
              ? BodySmallText(
                  '$viewString ${widget.model.totalComment} $commentsString',
                  weight: TextWeight.semiBold,
                  color: AppColorConstants.mainTextColor,
                )
              : Container(),
        ]).tP8);
  }

  Widget commentAndLikeWidget() {
    return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
      Obx(() => InkWell(
          onTap: () {
            postCardController.likeUnlikePost(
              post: widget.model,
            );
            // widget.likeTapHandler();
          },
          child: ThemeIconWidget(
            postCardController.likedPosts.contains(widget.model) ||
                    widget.model.isLike
                ? ThemeIcon.favFilled
                : ThemeIcon.fav,
            color: postCardController.likedPosts.contains(widget.model) ||
                    widget.model.isLike
                ? AppColorConstants.red
                : AppColorConstants.iconColor,
          ))),
      const SizedBox(
        width: 5,
      ),
      Obx(() {
        int totalLikes = 0;
        if (postCardController.likedPosts.contains(widget.model)) {
          PostModel post = postCardController.likedPosts
              .where((e) => e.id == widget.model.id)
              .first;
          totalLikes = post.totalLike;
        } else {
          totalLikes = widget.model.totalLike;
        }
        return totalLikes > 0
            ? BodyLargeText(
                '${widget.model.totalLike}',
                weight: TextWeight.bold,
              ).ripple(() {
                Get.to(() => LikedByUsers(
                      postId: widget.model.id,
                    ));
              })
            : Container();
      }),
      const SizedBox(
        width: 20,
      ),
      ThemeIconWidget(
        ThemeIcon.chat,
        color: AppColorConstants.iconColor,
      ).ripple(() {
        openComments();
      }),
      const SizedBox(
        width: 20,
      ),
      ThemeIconWidget(
        ThemeIcon.share,
        color: AppColorConstants.iconColor,
      ).ripple(() {
        showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            isScrollControlled: true,
            builder: (context) =>
                FractionallySizedBox(heightFactor: 0.95, child: sharePost()));
      }),
      if (!widget.model.isMyPost)
        const ThemeIconWidget(
          ThemeIcon.gift,
        ).hp(20).ripple(() {
          showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return FractionallySizedBox(
                    heightFactor: 0.8,
                    child: GiftsPageView(giftSelectedCompletion: (gift) {
                      Get.back();
                      homeController.sendPostGift(
                          gift, widget.model.user.id, widget.model.id);
                      Get.back();
                    }));
              });
        }),
      const Spacer(),
      if (widget.model.contentType == PostContentType.competitionAdded)
        Row(
          children: [
            const ThemeIconWidget(
              ThemeIcon.competition,
              size: 20,
            ),
            const SizedBox(
              width: 5,
            ),
            BodyMediumText(widget.model.competition!.isPast ||
                    widget.model.competition!.isJoined
                ? viewString.tr
                : joinString.tr)
          ],
        ).ripple(() {
          Get.to(() => CompetitionDetailScreen(
              competitionId: widget.model.competition!.id,
              refreshPreviousScreen: () {}));
        }),
      if (widget.model.contentType == PostContentType.competitionResultDeclared)
        Row(
          children: [
            const ThemeIconWidget(
              ThemeIcon.competition,
              size: 20,
            ),
            const SizedBox(
              width: 5,
            ),
            BodyMediumText(viewResultString.tr)
          ],
        ).ripple(() {
          Get.to(() => CompetitionDetailScreen(
              competitionId: widget.model.competition!.id,
              refreshPreviousScreen: () {}));
        }),
      if (widget.model.contentType == PostContentType.club)
        Row(
          children: [
            const ThemeIconWidget(
              ThemeIcon.userGroup,
              size: 20,
            ),
            const SizedBox(
              width: 5,
            ),
            BodyMediumText(widget.model.createdClub!.isJoined == true
                ? viewString.tr
                : joinString.tr)
          ],
        ).ripple(() {
          ClubsController clubController = Get.find();
          clubController.getClubDetail(widget.model.createdClub!.id!, (club) {
            Get.to(() => ClubDetail(
                  club: club,
                  needRefreshCallback: () {},
                  deleteCallback: (club) {},
                ));
          });
        }),
      const SizedBox(
        width: 20,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: Obx(() => ThemeIconWidget(
                  postCardController.savedPosts.contains(widget.model) ||
                          widget.model.isSaved
                      ? ThemeIcon.bookMarked
                      : ThemeIcon.bookMark,
                  color: widget.model.isSaved ||
                          postCardController.savedPosts.contains(widget.model)
                      ? AppColorConstants.themeColor
                      : AppColorConstants.iconColor,
                  // size: 25,
                )),
          ).ripple(() {
            postCardController.saveUnSavePost(post: widget.model);
          }),
          if (widget.model.isMyPost)
            BodyLargeText(
              viewGiftString.tr,
              // weight: TextWeight.regular,
            ).lp(20).ripple(() {
              showModalBottomSheet<void>(
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) {
                    _postGiftController
                        .fetchReceivedTimelineStickerGift(widget.model.id);
                    return FractionallySizedBox(
                        heightFactor: 1.5,
                        child: ReceivedGiftsList(
                          postId: widget.model.id,
                        ));
                  });
            }),
        ],
      )
    ]);
  }

  Widget sharePost() {
    return Container(
      color: AppColorConstants.cardColor,
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                BodyMediumText(
                  shareToFeedString.tr,
                  weight: TextWeight.semiBold,
                ),
                const SizedBox(
                  height: 10,
                ),
                ReSharePost(
                  post: widget.model,
                ),
                divider(height: 0.5).vP16,
                BodyMediumText(
                  sendSeparatelyToFriends.tr,
                  weight: TextWeight.semiBold,
                ),
                Expanded(child: SelectFollowingUserForMessageSending(
                    // post: widget.model,
                    sendToUserCallback: (user) {
                  selectUserForChatController.sendMessage(
                      toUser: user, post: widget.model);
                })),
              ],
            ).p(DesignConstants.horizontalPadding),
          ),
          Container(
            color: AppColorConstants.backgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      color: AppColorConstants.themeColor,
                      child: const ThemeIconWidget(
                        ThemeIcon.share,
                        color: Colors.white,
                      ),
                    ).circular,
                    const SizedBox(
                      height: 5,
                    ),
                    BodySmallText(shareToString.tr)
                  ],
                ).ripple(() {
                  postCardController.sharePost(post: widget.model);
                }),
                const SizedBox(
                  width: 20,
                ),
                Column(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      color: AppColorConstants.themeColor,
                      child: const ThemeIconWidget(
                        ThemeIcon.copyToClipboard,
                        color: Colors.white,
                      ),
                    ).circular,
                    const SizedBox(
                      height: 5,
                    ),
                    BodySmallText(copyLinkString.tr)
                  ],
                ).ripple(() async {
                  AppUtil.showToast(message: copiedString.tr, isSuccess: true);

                  await Clipboard.setData(
                      ClipboardData(text: widget.model.shareLink));
                })
              ],
            ).setPadding(
                left: 100,
                right: 100,
                top: DesignConstants.horizontalPadding,
                bottom: DesignConstants.horizontalPadding),
          )
        ],
      ),
    ).topRounded(40);
  }

  void addNewMessage() {
    if (commentInputField.text.trim().isNotEmpty) {
      FocusScope.of(context).unfocus();

      final filter = ProfanityFilter();
      bool hasProfanity = filter.hasProfanity(commentInputField.text);
      if (hasProfanity) {
        AppUtil.showToast(message: notAllowedMessageString.tr, isSuccess: true);
        return;
      }

      _commentsController.postCommentsApiCall(
          comment: commentInputField.text.trim(),
          postId: widget.model.id,
          commentPosted: () {
            setState(() {
              widget.model.totalComment += 1;
            });
          });
      commentInputField.text = '';
    }
  }

  Widget addPostUserInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
            height: 30,
            width: 30,
            child: UserAvatarView(
              size: 30,
              user: widget.model.user,
              onTapHandler: () {
                openProfile();
              },
            )),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                BodySmallText(
                  widget.model.user.userName,
                  weight: TextWeight.medium,
                ).ripple(() {
                  openProfile();
                }),
                if (widget.model.user.isVerified) verifiedUserTag().rP8,
                if (widget.model.postedInClub != null)
                  Expanded(
                    child: BodyLargeText(
                      ' (${widget.model.postedInClub!.name})',
                      weight: TextWeight.semiBold,
                      color: AppColorConstants.themeColor,
                      maxLines: 1,
                    ).ripple(() {
                      openClubDetail();
                    }),
                  ),
              ],
            ),
            widget.model.user.city != null
                ? BodySmallText(
                    '${widget.model.user.city!}, ${widget.model.user.country!}',
                  )
                : Container()
          ],
        )),
        // postTimeView().rp(DesignConstants.horizontalPadding),
        SizedBox(
          height: 20,
          width: 20,
          child: ThemeIconWidget(
            ThemeIcon.more,
            color: AppColorConstants.iconColor,
            size: 25,
          ),
        ).ripple(() {
          openActionPopup();
        })
      ],
    );
  }

  RichText _convertHashtag(String text) {
    List<String> split = text.split(' ');

    return RichText(
        text: TextSpan(children: [
      // TextSpan(
      //   text: '${widget.model.user.userName}  ',
      //   style: TextStyle(
      //       color: AppColorConstants.mainTextColor, fontWeight: FontWeight.w900),
      //   recognizer: TapGestureRecognizer()
      //     ..onTap = () {
      //       openProfile();
      //     },
      // ),
      for (String text in split)
        text.startsWith('#')
            ? TextSpan(
                text: '$text ',
                style: TextStyle(
                    color: AppColorConstants.themeColor,
                    fontSize: FontSizes.b3,
                    fontWeight: FontWeight.w700),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    postTextTapHandler(post: widget.model, text: text);
                    // widget.textTapHandler(text);
                  },
              )
            : text.startsWith('@')
                ? TextSpan(
                    text: '$text ',
                    style: TextStyle(
                        color: AppColorConstants.themeColor,
                        fontSize: FontSizes.b3,
                        fontWeight: FontWeight.w700),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // widget.textTapHandler(text);
                        postTextTapHandler(post: widget.model, text: text);
                      },
                  )
                : TextSpan(
                    text: '$text ',
                    style: TextStyle(
                        color: AppColorConstants.mainTextColor,
                        fontSize: FontSizes.b3,
                        fontWeight: FontWeight.w400))
    ]));
  }

  postTextTapHandler({required PostModel post, required String text}) {
    if (text.startsWith('#')) {
      PostSearchQuery query = PostSearchQuery();
      query.hashTag = text.replaceAll('#', '');
      _postController.setPostSearchQuery(query: query, callback: () {});

      Get.to(() => const Posts());
      // _postController.getPosts();
    } else {
      String userTag = text.replaceAll('@', '');
      if (post.mentionedUsers
          .where((element) => element.userName == userTag)
          .isNotEmpty) {
        int mentionedUserId = post.mentionedUsers
            .where((element) => element.userName == userTag)
            .first
            .id;
        Get.to(() => OtherUserProfile(userId: mentionedUserId))!.then((value) {
          _postController.getPosts(() {});
        });
      } else {
        // print('not found');
      }
    }
  }

  void openActionPopup() {
    Get.bottomSheet(Container(
      color: AppColorConstants.cardColor.darken(),
      child: widget.model.user.isMe
          ? Wrap(
              children: [
                ListTile(
                    title: Center(
                        child: Heading6Text(
                      editPostString.tr,
                      weight: TextWeight.semiBold,
                    )),
                    onTap: () async {
                      Get.back();
                      Get.to(() => EditPostScreen(post: widget.model));
                    }),
                ListTile(
                    title: Center(
                        child: Heading6Text(
                      deletePostString.tr,
                      weight: TextWeight.bold,
                    )),
                    onTap: () async {
                      Get.back();
                      postCardController.deletePost(
                          post: widget.model,
                          callback: () {
                            widget.removePostHandler();
                          });
                    }),
                divider(),

                ListTile(
                    title: Center(child: BodyLargeText(cancelString.tr)),
                    onTap: () => Get.back()),
                const SizedBox(
                  height: 25,
                )
              ],
            )
          : Wrap(
              children: [
                ListTile(
                    title: Center(
                        child: Heading6Text(
                      reportString.tr,
                      weight: TextWeight.bold,
                    )),
                    onTap: () async {
                      Get.back();

                      AppUtil.showConfirmationAlert(
                          title: reportString.tr,
                          subTitle: areYouSureToReportPostString.tr,
                          okHandler: () {
                            postCardController.reportPost(
                                post: widget.model,
                                callback: () {
                                  widget.removePostHandler();
                                });
                          });
                    }),
                divider(),
                ListTile(
                    title: Center(
                        child: Heading6Text(blockUserString.tr,
                            weight: TextWeight.bold)),
                    onTap: () async {
                      Get.back();
                      AppUtil.showConfirmationAlert(
                          title: blockString.tr,
                          subTitle: areYouSureToBlockUserString.tr,
                          okHandler: () {
                            postCardController.blockUser(
                                userId: widget.model.user.id,
                                callback: () {
                                  widget.blockUserHandler();
                                });
                          });
                    }),
                divider(),

                ListTile(
                    title: Center(
                      child: Heading6Text(
                        cancelString.tr,
                        weight: TextWeight.regular,
                        color: AppColorConstants.red,
                      ),
                    ),
                    onTap: () => Get.back()),
                const SizedBox(
                  height: 25,
                )
              ],
            ),
    ).round(40));
  }

  void openComments() {
    Get.to(() => CommentsScreen(
          isPopup: true,
          model: widget.model,
          commentPostedCallback: () {
            setState(() {
              widget.model.totalComment += 1;
            });
          },
          commentDeletedCallback: () {
            setState(() {
              widget.model.totalComment -= 1;
            });
          },
        ));
  }

  void openProfile() async {
    if (widget.model.user.isMe) {
      Get.to(() => const MyProfile(
            showBack: true,
          ));
    } else {
      _profileController.otherUserProfileView(
          refId: widget.model.id, sourceType: 1);
      Get.to(() => OtherUserProfile(userId: widget.model.user.id));
    }
  }

  void openClubDetail() async {
    Get.to(() => ClubDetail(
        club: widget.model.postedInClub!,
        needRefreshCallback: () {},
        deleteCallback: (club) {}));
  }
}

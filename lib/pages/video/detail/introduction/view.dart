import 'package:flutter/gestures.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pilipala/common/constants.dart';
import 'package:pilipala/common/widgets/http_error.dart';
import 'package:pilipala/pages/video/detail/index.dart';
import 'package:pilipala/common/widgets/network_img_layer.dart';
import 'package:pilipala/common/widgets/stat/danmu.dart';
import 'package:pilipala/common/widgets/stat/view.dart';
import 'package:pilipala/models/video_detail_res.dart';
import 'package:pilipala/pages/video/detail/introduction/controller.dart';
import 'package:pilipala/utils/feed_back.dart';
import 'package:pilipala/utils/storage.dart';
import 'package:pilipala/utils/utils.dart';

import 'widgets/action_item.dart';
import 'widgets/action_row_item.dart';
import 'widgets/fav_panel.dart';
import 'widgets/intro_detail.dart';
import 'widgets/season.dart';

class VideoIntroPanel extends StatefulWidget {
  const VideoIntroPanel({Key? key}) : super(key: key);

  @override
  State<VideoIntroPanel> createState() => _VideoIntroPanelState();
}

class _VideoIntroPanelState extends State<VideoIntroPanel>
    with AutomaticKeepAliveClientMixin {
  final VideoIntroController videoIntroController =
      Get.put(VideoIntroController(), tag: Get.arguments['heroTag']);
  VideoDetailData? videoDetail;

  // 添加页面缓存
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    videoIntroController.videoDetail.listen((value) {
      videoDetail = value;
    });
  }

  @override
  void dispose() {
    videoIntroController.onClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: videoIntroController.queryVideoIntro(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data['status']) {
            // 请求成功
            // return _buildView(context, false, videoDetail);
            return Obx(
              () => VideoInfo(
                  loadingStatus: false,
                  videoDetail: videoIntroController.videoDetail.value),
            );
          } else {
            // 请求错误
            return HttpError(
              errMsg: snapshot.data['msg'],
              fn: () => Get.back(),
            );
          }
        } else {
          return VideoInfo(loadingStatus: true, videoDetail: videoDetail);
        }
      },
    );
  }
}

class VideoInfo extends StatefulWidget {
  final bool loadingStatus;
  final VideoDetailData? videoDetail;

  const VideoInfo({Key? key, this.loadingStatus = false, this.videoDetail})
      : super(key: key);

  @override
  State<VideoInfo> createState() => _VideoInfoState();
}

class _VideoInfoState extends State<VideoInfo> with TickerProviderStateMixin {
  Map videoItem = Get.put(VideoIntroController()).videoItem!;
  final VideoIntroController videoIntroController =
      Get.put(VideoIntroController(), tag: Get.arguments['heroTag']);
  bool isExpand = false;

  late VideoDetailController? videoDetailCtr;
  Box localCache = GStrorage.localCache;
  late double sheetHeight;

  @override
  void initState() {
    super.initState();

    videoDetailCtr =
        Get.find<VideoDetailController>(tag: Get.arguments['heroTag']);
    sheetHeight = localCache.get('sheetHeight');
  }

  // 收藏
  showFavBottomSheet() {
    if (videoIntroController.user.get(UserBoxKey.userMid) == null) {
      SmartDialog.showToast('账号未登录');
      return;
    }
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) {
        return FavPanel(ctr: videoIntroController);
      },
    );
  }

  // 视频介绍
  showIntroDetail() {
    feedBack();
    showBottomSheet(
      context: context,
      enableDrag: true,
      builder: (BuildContext context) {
        return IntroDetail(videoDetail: widget.videoDetail!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData t = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.only(
          left: StyleString.safeSpace, right: StyleString.safeSpace, top: 10),
      sliver: SliverToBoxAdapter(
        child: !widget.loadingStatus || videoItem.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => showIntroDetail(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            !widget.loadingStatus
                                ? widget.videoDetail!.title
                                : videoItem['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: IconButton(
                            style: ButtonStyle(
                              padding:
                                  MaterialStateProperty.all(EdgeInsets.zero),
                              backgroundColor:
                                  MaterialStateProperty.resolveWith((states) {
                                return t.highlightColor.withOpacity(0.2);
                              }),
                            ),
                            onPressed: () => showIntroDetail(),
                            icon: const Icon(Icons.more_horiz),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => showIntroDetail(),
                    child: Row(
                      children: [
                        StatView(
                          theme: 'gray',
                          view: !widget.loadingStatus
                              ? widget.videoDetail!.stat!.view
                              : videoItem['stat'].view,
                          size: 'medium',
                        ),
                        const SizedBox(width: 10),
                        StatDanMu(
                          theme: 'gray',
                          danmu: !widget.loadingStatus
                              ? widget.videoDetail!.stat!.danmaku
                              : videoItem['stat'].danmaku,
                          size: 'medium',
                        ),
                        const SizedBox(width: 10),
                        Text(
                          Utils.dateFormat(
                              !widget.loadingStatus
                                  ? widget.videoDetail!.pubdate
                                  : videoItem['pubdate'],
                              formatType: 'detail'),
                          style: TextStyle(
                            fontSize: 12,
                            color: t.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  // 点赞收藏转发 布局样式1
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 7, bottom: 7),
                    scrollDirection: Axis.horizontal,
                    child: actionRow(
                      context,
                      videoIntroController,
                      videoDetailCtr,
                    ),
                  ),
                  // 点赞收藏转发 布局样式2
                  // actionGrid(context, videoIntroController),
                  // 合集
                  if (!widget.loadingStatus &&
                      widget.videoDetail!.ugcSeason != null) ...[
                    SeasonPanel(
                      ugcSeason: widget.videoDetail!.ugcSeason!,
                      cid: widget.videoDetail!.pages!.first.cid,
                      sheetHeight: sheetHeight,
                      changeFuc: (bvid, cid, aid) => videoIntroController
                          .changeSeasonOrbangu(bvid, cid, aid),
                    )
                  ],
                  GestureDetector(
                    onTap: () {
                      feedBack();
                      int mid = !widget.loadingStatus
                          ? widget.videoDetail!.owner!.mid
                          : videoItem['owner'].mid;
                      String face = !widget.loadingStatus
                          ? widget.videoDetail!.owner!.face
                          : videoItem['owner'].face;
                      Get.toNamed('/member?mid=$mid', arguments: {
                        'face': face,
                        'heroTag': (mid + 99).toString()
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 12, bottom: 12, left: 4, right: 4),
                      child: Row(
                        children: [
                          NetworkImgLayer(
                            type: 'avatar',
                            src: !widget.loadingStatus
                                ? widget.videoDetail!.owner!.face
                                : videoItem['owner'].face,
                            width: 34,
                            height: 34,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            !widget.loadingStatus
                                ? widget.videoDetail!.owner!.name
                                : videoItem['owner'].name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.loadingStatus
                                ? '-'
                                : Utils.numFormat(
                                    videoIntroController.userStat['follower']),
                            style: TextStyle(
                                fontSize: t.textTheme.labelSmall!.fontSize,
                                color: t.colorScheme.outline),
                          ),
                          const Spacer(),
                          AnimatedOpacity(
                            opacity: widget.loadingStatus ? 0 : 1,
                            duration: const Duration(milliseconds: 150),
                            child: SizedBox(
                              height: 32,
                              child: Obx(
                                () => videoIntroController
                                        .followStatus.isNotEmpty
                                    ? TextButton(
                                        onPressed: () => videoIntroController
                                            .actionRelationMod(),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.only(
                                              left: 8, right: 8),
                                          foregroundColor:
                                              videoIntroController.followStatus[
                                                          'attribute'] !=
                                                      0
                                                  ? t.colorScheme.outline
                                                  : t.colorScheme.onPrimary,
                                          backgroundColor: videoIntroController
                                                          .followStatus[
                                                      'attribute'] !=
                                                  0
                                              ? t.colorScheme.onInverseSurface
                                              : t.colorScheme
                                                  .primary, // 设置按钮背景色
                                        ),
                                        child: Text(
                                          videoIntroController.followStatus[
                                                      'attribute'] !=
                                                  0
                                              ? '已关注'
                                              : '关注',
                                          style: TextStyle(
                                              fontSize: t.textTheme.labelMedium!
                                                  .fontSize),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: () => videoIntroController
                                            .actionRelationMod(),
                                        child: const Text('关注'),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      ),
    );
  }

  Widget actionGrid(BuildContext context, videoIntroController) {
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: SizedBox(
          height: constraints.maxWidth / 5 * 0.8,
          child: GridView.count(
            primary: false,
            padding: const EdgeInsets.all(0),
            crossAxisCount: 5,
            childAspectRatio: 1.25,
            children: <Widget>[
              Obx(
                () => ActionItem(
                    icon: const Icon(FontAwesomeIcons.thumbsUp),
                    selectIcon: const Icon(FontAwesomeIcons.solidThumbsUp),
                    onTap: () => videoIntroController.actionLikeVideo(),
                    selectStatus: videoIntroController.hasLike.value,
                    loadingStatus: widget.loadingStatus,
                    text: !widget.loadingStatus
                        ? widget.videoDetail!.stat!.like!.toString()
                        : '-'),
              ),
              ActionItem(
                  icon: const Icon(FontAwesomeIcons.clock),
                  onTap: () => videoIntroController.actionShareVideo(),
                  selectStatus: false,
                  loadingStatus: widget.loadingStatus,
                  text: '稍后再看'),
              Obx(
                () => ActionItem(
                    icon: const Icon(FontAwesomeIcons.b),
                    selectIcon: const Icon(FontAwesomeIcons.b),
                    onTap: () => videoIntroController.actionCoinVideo(),
                    selectStatus: videoIntroController.hasCoin.value,
                    loadingStatus: widget.loadingStatus,
                    text: !widget.loadingStatus
                        ? widget.videoDetail!.stat!.coin!.toString()
                        : '-'),
              ),
              Obx(
                () => ActionItem(
                    icon: const Icon(FontAwesomeIcons.star),
                    selectIcon: const Icon(FontAwesomeIcons.solidStar),
                    // onTap: () => videoIntroController.actionFavVideo(),
                    onTap: () => showFavBottomSheet(),
                    selectStatus: videoIntroController.hasFav.value,
                    loadingStatus: widget.loadingStatus,
                    text: !widget.loadingStatus
                        ? widget.videoDetail!.stat!.favorite!.toString()
                        : '-'),
              ),
              ActionItem(
                  icon: const Icon(FontAwesomeIcons.shareFromSquare),
                  onTap: () => videoIntroController.actionShareVideo(),
                  selectStatus: false,
                  loadingStatus: widget.loadingStatus,
                  text: !widget.loadingStatus
                      ? widget.videoDetail!.stat!.share!.toString()
                      : '-'),
            ],
          ),
        ),
      );
    });
  }

  Widget actionRow(BuildContext context, videoIntroController, videoDetailCtr) {
    return Row(children: [
      Obx(
        () => ActionRowItem(
          icon: const Icon(FontAwesomeIcons.thumbsUp),
          onTap: () => videoIntroController.actionLikeVideo(),
          selectStatus: videoIntroController.hasLike.value,
          loadingStatus: widget.loadingStatus,
          text: !widget.loadingStatus
              ? widget.videoDetail!.stat!.like!.toString()
              : '-',
        ),
      ),
      const SizedBox(width: 8),
      Obx(
        () => ActionRowItem(
          icon: const Icon(FontAwesomeIcons.b),
          onTap: () => videoIntroController.actionCoinVideo(),
          selectStatus: videoIntroController.hasCoin.value,
          loadingStatus: widget.loadingStatus,
          text: !widget.loadingStatus
              ? widget.videoDetail!.stat!.coin!.toString()
              : '-',
        ),
      ),
      const SizedBox(width: 8),
      Obx(
        () => ActionRowItem(
          icon: const Icon(FontAwesomeIcons.heart),
          onTap: () => showFavBottomSheet(),
          selectStatus: videoIntroController.hasFav.value,
          loadingStatus: widget.loadingStatus,
          text: !widget.loadingStatus
              ? widget.videoDetail!.stat!.favorite!.toString()
              : '-',
        ),
      ),
      const SizedBox(width: 8),
      ActionRowItem(
        icon: const Icon(FontAwesomeIcons.comment),
        onTap: () {
          videoDetailCtr.tabCtr.animateTo(1);
        },
        selectStatus: false,
        loadingStatus: widget.loadingStatus,
        text: !widget.loadingStatus
            ? widget.videoDetail!.stat!.reply!.toString()
            : '-',
      ),
      const SizedBox(width: 8),
      ActionRowItem(
          icon: const Icon(FontAwesomeIcons.share),
          onTap: () => videoIntroController.actionShareVideo(),
          selectStatus: false,
          loadingStatus: widget.loadingStatus,
          // text: !widget.loadingStatus
          //     ? widget.videoDetail!.stat!.share!.toString()
          //     : '-',
          text: '转发'),
    ]);
  }

  InlineSpan buildContent(BuildContext context, content) {
    String desc = content.desc;
    List descV2 = content.descV2;
    // type
    // 1 普通文本
    // 2 @用户
    List<InlineSpan> spanChilds = [];
    if (descV2.isNotEmpty) {
      for (var i = 0; i < descV2.length; i++) {
        if (descV2[i].type == 1) {
          spanChilds.add(TextSpan(text: descV2[i].rawText));
        } else if (descV2[i].type == 2) {
          spanChilds.add(
            TextSpan(
              text: '@${descV2[i].rawText}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  String heroTag = Utils.makeHeroTag(descV2[i].bizId);
                  Get.toNamed(
                    '/member?mid=${descV2[i].bizId}',
                    arguments: {'face': '', 'heroTag': heroTag},
                  );
                },
            ),
          );
        }
      }
    } else {
      spanChilds.add(TextSpan(text: desc));
    }
    return TextSpan(children: spanChilds);
  }
}

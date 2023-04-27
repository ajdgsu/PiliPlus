import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pilipala/common/widgets/network_img_layer.dart';
import 'package:pilipala/models/video/reply/item.dart';
import 'package:pilipala/utils/utils.dart';

class ReplyItem extends StatelessWidget {
  ReplyItem({super.key, this.replyItem, required this.isUp});
  ReplyItemModel? replyItem;
  bool isUp = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 0),
            child: content(context),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.08),
          )
        ],
      ),
    );
  }

  Widget lfAvtar(context) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      child: NetworkImgLayer(
        src: replyItem!.member!.avatar,
        width: 30,
        height: 30,
        type: 'avatar',
      ),
    );
  }

  Widget content(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 头像、昵称
        Row(
          // 两端对齐
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            GestureDetector(
              // onTap: () =>
              //     Get.toNamed('/member/${reply.userName}', parameters: {
              //   'memberAvatar': reply.avatar,
              //   'heroTag': reply.userName + heroTag,
              // }),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  lfAvtar(context),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            replyItem!.member!.uname!,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                  color: replyItem!.isUp!
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Image.asset(
                            'assets/images/lv/lv${replyItem!.member!.level}.png',
                            height: 13,
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
        // title
        Container(
          margin: const EdgeInsets.only(top: 0, left: 45, right: 6),
          child: SelectableRegion(
            magnifierConfiguration: const TextMagnifierConfiguration(),
            focusNode: FocusNode(),
            selectionControls: MaterialTextSelectionControls(),
            child: Text.rich(
              style: const TextStyle(height: 1.65),
              TextSpan(
                children: [
                  buildContent(context, replyItem!.content!),
                ],
              ),
            ),
          ),
        ),
        // 操作区域
        bottonAction(context, replyItem!.replyControl),
        if (replyItem!.replies!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: ReplyItemRow(
              replies: replyItem!.replies,
              replyControl: replyItem!.replyControl,
            ),
          ),
        ],
      ],
    );
  }

  // 感谢、回复、复制
  Widget bottonAction(context, replyControl) {
    var color = Theme.of(context).colorScheme.outline;
    return Row(
      children: [
        const SizedBox(width: 48),
        Text(
          Utils.dateFormat(replyItem!.ctime),
          style: Theme.of(context)
              .textTheme
              .labelMedium!
              .copyWith(color: Theme.of(context).colorScheme.outline),
        ),
        if (replyItem!.isTop!) ...[
          Text(
            ' • 置顶',
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
        if (replyControl!.isUpTop!) ...[
          Text(
            ' • 超赞',
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          // const SizedBox(width: 4),
        ],
        const Spacer(),
        SizedBox(
          height: 35,
          child: TextButton(
            child: Row(
              children: [
                Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  replyItem!.like.toString(),
                  style: TextStyle(
                      color: color,
                      fontSize:
                          Theme.of(context).textTheme.labelSmall!.fontSize),
                ),
              ],
            ),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 5)
      ],
    );
  }
}

// ignore: must_be_immutable
class ReplyItemRow extends StatelessWidget {
  ReplyItemRow({
    super.key,
    this.replies,
    this.replyControl,
  });
  List? replies;
  ReplyControl? replyControl;

  @override
  Widget build(BuildContext context) {
    bool isShow = replyControl!.isShow!;
    int extraRow = replyControl != null && isShow ? 1 : 0;
    return Container(
      margin: const EdgeInsets.only(left: 42, right: 4, top: 0),
      child: Material(
        color: Theme.of(context).colorScheme.onInverseSurface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        clipBehavior: Clip.hardEdge,
        animationDuration: Duration.zero,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: replies!.length + extraRow,
          itemBuilder: (context, index) {
            if (extraRow == 1 && index == replies!.length) {
              // 有楼中楼回复，在最后显示
              return InkWell(
                onTap: () {},
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.labelMedium!.fontSize,
                      ),
                      children: [
                        if (replyControl!.upReply!)
                          const TextSpan(text: 'up主等人 '),
                        TextSpan(
                          text: replyControl!.entryText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8, index == 0 ? 8 : 4, 8, 4),
                    child: Text.rich(
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      TextSpan(
                        children: [
                          if (replies![index].isUp)
                            TextSpan(
                              text: 'UP • ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .fontSize,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          TextSpan(
                            text: replies![index].member.uname + ' ',
                            style: TextStyle(
                              fontSize: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .fontSize,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => {
                                    print('跳转至用户主页'),
                                  },
                          ),
                          buildContent(context, replies![index].content),
                        ],
                      ),
                    ),
                  ));
            }
          },
        ),
      ),
    );
  }
}

InlineSpan buildContent(BuildContext context, content) {
  if (content.emote.isEmpty &&
      content.atNameToMid.isEmpty &&
      content.jumpUrl.isEmpty &&
      content.pictures.isEmpty) {
    return TextSpan(text: content.message);
  }
  List<InlineSpan> spanChilds = [];
  // 匹配表情
  String matchEmote = content.message.splitMapJoin(
    RegExp(r"\[.*?\]"),
    onMatch: (Match match) {
      String matchStr = match[0]!;
      if (content.emote.isNotEmpty) {
        if (content.emote.keys.contains(matchStr)) {
          spanChilds.add(
            WidgetSpan(
              child: NetworkImgLayer(
                src: content.emote[matchStr]['url'],
                width: 20,
                height: 20,
              ),
            ),
          );
        } else {
          spanChilds.add(TextSpan(text: matchStr));
          return matchStr;
        }
      }
      return '';
    },
    onNonMatch: (String str) {
      // 匹配@用户
      String matchMember = str;
      if (content.atNameToMid.isNotEmpty) {
        matchMember = str.splitMapJoin(
          RegExp(r"@.*:"),
          onMatch: (Match match) {
            if (match[0] != null) {
              content.atNameToMid.forEach((key, value) {
                spanChilds.add(
                  TextSpan(
                    text: '@$key ',
                    style: TextStyle(
                      fontSize:
                          Theme.of(context).textTheme.titleSmall!.fontSize,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => {
                            print('跳转至用户主页'),
                          },
                  ),
                );
              });
            }
            return '';
          },
          onNonMatch: (String str) {
            spanChilds.add(TextSpan(text: str));
            return str;
          },
        );
      } else {
        matchMember = str;
      }

      // 匹配 jumpUrl
      String matchUrl = matchMember;
      if (content.jumpUrl.isNotEmpty) {
        List urlKeys = content.jumpUrl.keys.toList();
        matchUrl = matchMember.splitMapJoin(
          RegExp("(?:${urlKeys.join("|")})"),
          onMatch: (Match match) {
            String matchStr = match[0]!;
            // spanChilds.add(TextSpan(text: matchStr));
            spanChilds.add(
              TextSpan(
                text: content.jumpUrl[matchStr]['title'],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => {
                        print('Url 点击'),
                      },
              ),
            );
            return '';
          },
          onNonMatch: (String str) {
            spanChilds.add(TextSpan(text: str));
            return str;
          },
        );
      }

      if (content.atNameToMid.isEmpty && content.jumpUrl.isEmpty) {
        spanChilds.add(TextSpan(text: str));
      }
      return str;
    },
  );

  // 图片渲染
  if (content.pictures.isNotEmpty) {
    spanChilds.add(
      const TextSpan(text: '\n'),
    );
    for (var i = 0; i < content.pictures.length; i++) {
      spanChilds.add(
        WidgetSpan(
          child: SizedBox(
            height: 180,
            child: NetworkImgLayer(
              src: content.pictures[i]['img_src'],
              width: 200,
              height: 200 *
                  content.pictures[i]['img_height'] /
                  content.pictures[i]['img_width'],
            ),
          ),
        ),
      );
    }
  }
  // spanChilds.add(TextSpan(text: matchMember));
  return TextSpan(children: spanChilds);
}
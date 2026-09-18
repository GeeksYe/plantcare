/// 数据模型 —— 当前全部为展示数据，后续接入服务器时替换来源即可
class Plant {
  final String id;
  final String species; // 物种名，如 龟背竹
  final String defaultNickname; // 默认昵称
  final String speciesLatin;
  final String image; // assets 路径
  final int health; // 0-100
  final bool needsWater;
  final bool needFertilizer; // 是否需要施肥
  final int humidity; // 土壤湿度 %
  final int temperature; // ℃
  final int light; // 光照 %
  final int waterInDays; // 距下次浇水天数
  final int careDays; // 养护天数
  final String? warning; // 智能花盆预警

  const Plant({
    required this.id,
    required this.species,
    required this.defaultNickname,
    required this.speciesLatin,
    required this.image,
    required this.health,
    required this.needsWater,
    required this.needFertilizer,
    required this.humidity,
    required this.temperature,
    required this.light,
    required this.waterInDays,
    required this.careDays,
    this.warning,
  });
}

class CareTask {
  final String id;
  final String plantId;
  final String title;
  final String subtitle;
  final String time;
  final String icon; // emoji
  final bool urgent;

  const CareTask({
    required this.id,
    required this.plantId,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    this.urgent = false,
  });
}

class Post {
  final String id;
  final String author;
  final String avatarEmoji;
  final String time;
  final String text;
  final String image; // 主图（assets 路径或本机文件路径）
  final int likes;
  final int comments;
  final List<String> tags; // 话题标签
  final bool isMurmur; // 碎碎念纯文字帖
  final List<String> images; // 多图（本机发布的内容）
  final String? videoPath; // 短视频（本机文件）
  final int videoSec; // 视频时长（秒）
  final String? avatarPath; // 发布者头像（本机照片）
  final bool mine; // 是否是本机发布的

  const Post({
    required this.id,
    required this.author,
    required this.avatarEmoji,
    required this.time,
    required this.text,
    required this.image,
    required this.likes,
    required this.comments,
    this.tags = const [],
    this.isMurmur = false,
    this.images = const [],
    this.videoPath,
    this.videoSec = 0,
    this.avatarPath,
    this.mine = false,
  });
}

class GrowthMilestone {
  final String label; // 首日 / 14天 ...
  final String note;
  final String status;

  const GrowthMilestone(this.label, this.note, this.status);
}

class WikiEntry {
  final String name;
  final String latin;
  final String image;
  final String tag;
  final String difficulty;

  const WikiEntry(this.name, this.latin, this.image, this.tag, this.difficulty);
}

class WikiQA {
  final String question;
  final String answer;

  const WikiQA(this.question, this.answer);
}

class GrowthRecord {
  final String date;
  final String action;
  final String plantName;
  final String icon;

  const GrowthRecord(this.date, this.action, this.plantName, this.icon);
}

/// 动态评论
class Comment {
  final String id;
  final String postId;
  final String author;
  final String avatarEmoji;
  final String? avatarPath;
  final String text;
  final String time;
  final int likes;
  final bool mine; // 是否本机发布

  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.avatarEmoji,
    this.avatarPath,
    required this.text,
    required this.time,
    this.likes = 0,
    this.mine = false,
  });
}

/// 用户勋章
class UserBadge {
  final String id;
  final String name;
  final String emoji;
  final String condition; // 获得条件
  final int colorValue; // 勋章主题色

  const UserBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.condition,
    required this.colorValue,
  });
}

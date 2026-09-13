import '../models.dart';

/// 展示数据（暂不接服务器）
class MockData {
  static const plants = <Plant>[
    Plant(
      id: 'p1',
      species: '龟背竹',
      defaultNickname: '皮卡丘',
      speciesLatin: 'Monstera deliciosa',
      image: 'assets/images/monstera.png',
      health: 92,
      needsWater: false,
      needFertilizer: true,
      humidity: 65,
      temperature: 24,
      light: 72,
      waterInDays: 3,
      careDays: 126,
      warning: null,
    ),
    Plant(
      id: 'p2',
      species: '绿萝',
      defaultNickname: '小翠',
      speciesLatin: 'Epipremnum aureum',
      image: 'assets/images/pothos.png',
      health: 88,
      needsWater: true,
      needFertilizer: false,
      humidity: 38,
      temperature: 25,
      light: 55,
      waterInDays: 0,
      careDays: 210,
      warning: '土壤湿度偏低，建议今日浇水',
    ),
    Plant(
      id: 'p3',
      species: '多肉',
      defaultNickname: '胖胖',
      speciesLatin: 'Echeveria elegans',
      image: 'assets/images/succulent.png',
      health: 96,
      needsWater: false,
      needFertilizer: false,
      humidity: 22,
      temperature: 23,
      light: 88,
      waterInDays: 6,
      careDays: 95,
      warning: null,
    ),
    Plant(
      id: 'p4',
      species: '琴叶榕',
      defaultNickname: '大提琴',
      speciesLatin: 'Ficus lyrata',
      image: 'assets/images/ficus.png',
      health: 81,
      needsWater: false,
      needFertilizer: true,
      humidity: 58,
      temperature: 22,
      light: 63,
      waterInDays: 2,
      careDays: 64,
      warning: '检测到叶片轻微黄斑，注意通风',
    ),
  ];

  static const todayTasks = <CareTask>[
    CareTask(
      id: 't1',
      plantId: 'p2',
      title: '给「小翠」浇水',
      subtitle: '土壤湿度 38%，低于舒适区间',
      time: '09:00',
      icon: '💧',
      urgent: true,
    ),
    CareTask(
      id: 't2',
      plantId: 'p1',
      title: '给「皮卡丘」施肥',
      subtitle: '营养状态偏低，建议施氮肥',
      time: '10:30',
      icon: '🌱',
    ),
    CareTask(
      id: 't3',
      plantId: 'p4',
      title: '「大提琴」转盆见光',
      subtitle: '光照不均，建议旋转 90°',
      time: '16:00',
      icon: '☀️',
    ),
  ];

  static const posts = <Post>[
    Post(
      id: 'b1',
      author: '绿野仙踪',
      avatarEmoji: '🪴',
      time: '2小时前',
      text: '我的龟背竹又冒新叶啦 🌿 分享今天的养护心得得～',
      image: 'assets/images/monstera.png',
      likes: 128,
      comments: 32,
      tags: ['#龟背竹', '#养护日记'],
    ),
    Post(
      id: 'b2',
      author: '今日碎碎念',
      avatarEmoji: '',
      time: '',
      text: '今天给家里的龟背竹换了新土，叶子都舒展开了～养护真是越养越有成就感',
      image: '',
      likes: 36,
      comments: 8,
      tags: ['#换盆', '#日常'],
      isMurmur: true,
    ),
    Post(
      id: 'b3',
      author: '多肉小馆',
      avatarEmoji: '🌵',
      time: '昨天',
      text: '绿萝垂下来的藤蔓太治愈了，剪了几枝水培送朋友 🌿',
      image: 'assets/images/pothos.png',
      likes: 86,
      comments: 19,
      tags: ['#绿萝', '#水培'],
    ),
    Post(
      id: 'b4',
      author: 'Fiona 的绿角落',
      avatarEmoji: '🍃',
      time: '昨天 20:36',
      text: '琴叶榕长到 1 米 2 了！控水心得：宁干勿湿，盆插竹签判断干湿最靠谱。',
      image: 'assets/images/ficus.png',
      likes: 89,
      comments: 15,
      tags: ['#琴叶榕', '#控水心得'],
    ),
  ];

  static const growthMilestones = <GrowthMilestone>[
    GrowthMilestone('首日', '移栽入智能花盆，叶片 4 片', '适应期'),
    GrowthMilestone('14天', '新叶展开，根系贴合盆土', '正常'),
    GrowthMilestone('30天', '第一片叶子开背 🎉', '里程碑'),
    GrowthMilestone('3个月', '株型饱满，叶片 9 片', '良好'),
    GrowthMilestone('6个月', '完整裂叶成株，进入稳定生长期', '优秀'),
  ];

  static const wikiEntries = <WikiEntry>[
    WikiEntry('龟背竹', 'Monstera deliciosa', 'assets/images/monstera.png', '观叶', '容易'),
    WikiEntry('绿萝', 'Epipremnum aureum', 'assets/images/pothos.png', '净化', '极易'),
    WikiEntry('月影系多肉', 'Echeveria elegans', 'assets/images/succulent.png', '多肉', '中等'),
    WikiEntry('琴叶榕', 'Ficus lyrata', 'assets/images/ficus.png', '观叶', '较难'),
  ];

  static const wikiQA = <WikiQA>[
    WikiQA('龟背竹叶子发黄怎么办？', '多为积水烂根或光照过强。先停水检查根系，剪除腐根后换疏松基质，移到明亮散射光处。'),
    WikiQA('多肉夏天可以施肥吗？', '高温休眠期不建议施肥。气温稳定在 30℃ 以下再少量施缓释肥，避免烧根。'),
  ];

  static const growthRecords = <GrowthRecord>[
    GrowthRecord('今天 09:12', '完成浇水 220ml', '小翠（绿萝）', '💧'),
    GrowthRecord('昨天 10:30', '施氮肥一次', '皮卡丘（龟背竹）', '🌱'),
    GrowthRecord('周三 16:00', '转盆 90° 均衡光照', '大提琴（琴叶榕）', '☀️'),
    GrowthRecord('周二 08:20', '识别出新植物「月影系多肉」', '胖胖（多肉）', '📸'),
  ];

  /// 用户勋章（默认解锁：新手园丁 / 绿植达人 / 打卡狂人）
  static const badges = <UserBadge>[
    UserBadge(id: 'newbie', name: '新手园丁', emoji: '🌱',
        condition: '添加第一株植物', colorValue: 0xFF22C55E),
    UserBadge(id: 'water', name: '浇水达人', emoji: '💧',
        condition: '累计完成 50 次浇水', colorValue: 0xFF38BDF8),
    UserBadge(id: 'detective', name: '植物侦探', emoji: '📸',
        condition: '完成 10 次 AI 识别', colorValue: 0xFF8B5CF6),
    UserBadge(id: 'streak', name: '打卡狂人', emoji: '🔥',
        condition: '连续打卡满 30 天', colorValue: 0xFFF97316),
    UserBadge(id: 'expert', name: '绿植达人', emoji: '🌿',
        condition: '养护天数满 100 天', colorValue: 0xFF15803D),
    UserBadge(id: 'forest', name: '森林之主', emoji: '🌳',
        condition: '同时养护 10 株植物', colorValue: 0xFF0EA5E9),
    UserBadge(id: 'scholar', name: '百科学者', emoji: '🏆',
        condition: '浏览 20 种植物百科', colorValue: 0xFFD97706),
    UserBadge(id: 'legend', name: '传奇园丁', emoji: '👑',
        condition: '养护天数满 365 天', colorValue: 0xFFEAB308),
  ];

  /// 预设头像（不想上传照片时可直接选用）
  static const presetAvatars = <String>['🌿', '🌱', '🌵', '🌸', '🍀', '🌻', '🌴', '🍃'];
}

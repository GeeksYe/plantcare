/// 常见家养绿植养护库（植物识别后给出光照/浇水/养护要点）
class SpeciesKb {
  const SpeciesKb._();

  static const entries = <Map<String, dynamic>>[
    {
      'name': '龟背竹',
      'aliases': ['龟背竹', '蓬莱蕉', '穿孔喜林芋'],
      'latin': 'Monstera deliciosa',
      'intro': '热带观叶植物，叶片开背极具辨识度，耐阴好养，是新手友好的大型绿植。',
      'light': '明亮散射光，忌强光直射，耐半阴',
      'water': '表土干透再浇透，约 7~10 天一次，冬季减少',
      'tip': '定期擦叶保持光泽；气生根可引导入土；怕冷，低于 10℃ 需保暖',
    },
    {
      'name': '绿萝',
      'aliases': ['绿萝', '黄金葛', '魔鬼藤'],
      'latin': 'Epipremnum aureum',
      'intro': '极易养护的垂吊/攀援绿植，水培土培皆可，净化空气能力强。',
      'light': '散射光，耐阴，忌暴晒',
      'water': '见干见湿，土表发白即浇，约 5~7 天一次',
      'tip': '水培勤换水防烂根；黄叶及时剪除；冬季控水保暖',
    },
    {
      'name': '吊兰',
      'aliases': ['吊兰', '垂盆草', '折鹤兰'],
      'latin': 'Chlorophytum comosum',
      'intro': '经典悬挂绿植，会从匍匐茎上长出小植株，皮实好养。',
      'light': '半阴散射光，忌强光',
      'water': '保持盆土微润，约 5~7 天一次',
      'tip': '小植株可剪下另行扦插；叶尖干枯多为空气过干，多喷雾',
    },
    {
      'name': '虎皮兰',
      'aliases': ['虎皮兰', '虎尾兰', '千岁兰'],
      'latin': 'Sansevieria trifasciata',
      'intro': '极耐旱的沙漠型观叶植物，夜间释放氧气，适合卧室。',
      'light': '喜光也耐阴，明亮处叶片更挺拔',
      'water': '干透浇透，约 15~20 天一次，最怕积水烂根',
      'tip': '冬季几乎停水；用排水极好的沙质土；少肥',
    },
    {
      'name': '多肉植物',
      'aliases': ['多肉', '玉露', '熊童子', '景天', '拟石莲'],
      'latin': 'Crassulaceae / various',
      'intro': '叶片储水的萌系植物，品种极多，核心在控水与光照。',
      'light': '充足直射光，光照不足易徒长摊开',
      'water': '干透浇透，约 10~15 天一次，夏季冬季控水',
      'tip': '配颗粒土保证透气；避免叶心积水；春秋生长季可露养',
    },
    {
      'name': '琴叶榕',
      'aliases': ['琴叶榕', '小提琴叶榕'],
      'latin': 'Ficus lyrata',
      'intro': '网红大型观叶植物，叶片如小提琴，对环境变化较敏感。',
      'light': '明亮散射光，每日 4 小时以上',
      'water': '表土干 2cm 再浇，约 7~10 天一次',
      'tip': '固定位置少移动；定期转盆受光均匀；通风防叶斑',
    },
    {
      'name': '发财树',
      'aliases': ['发财树', '马拉巴栗'],
      'latin': 'Pachira aquatica',
      'intro': '寓意吉祥的室内乔木，茎干膨大储水，极耐旱。',
      'light': '散射光，耐半阴',
      'water': '盆土干透再浇，约 10~15 天一次，宁干勿湿',
      'tip': '最忌频繁浇水烂根；保持通风；冬季控水',
    },
    {
      'name': '富贵竹',
      'aliases': ['富贵竹', '万年竹'],
      'latin': 'Dracaena sanderiana',
      'intro': '常见水培绿植，挺拔有节，寓意好，几乎不用土。',
      'light': '明亮散射光，忌直射',
      'water': '水培保持水位，约 7~10 天换水一次',
      'tip': '放水培专用营养液；忌自来水直接用，晾晒更佳；黄叶剪除',
    },
    {
      'name': '仙人掌',
      'aliases': ['仙人掌', '仙人球', '金琥'],
      'latin': 'Cactaceae',
      'intro': '极耐旱多刺植物，喜强光，几乎不用打理。',
      'light': '充足直射阳光',
      'water': '干透浇透，约 20~30 天一次，冬季停水',
      'tip': '配沙土；通风防腐烂；移栽戴手套防刺',
    },
    {
      'name': '芦荟',
      'aliases': ['芦荟', '库拉索芦荟'],
      'latin': 'Aloe vera',
      'intro': '药用与观赏兼具的多浆植物，叶肉可舒缓烫伤。',
      'light': '明亮散射光至温和直射',
      'water': '干透浇透，约 10~15 天一次',
      'tip': '怕积水；小侧芽可分株繁殖；室内越冬保暖',
    },
    {
      'name': '文竹',
      'aliases': ['文竹', '云片松'],
      'latin': 'Asparagus setaceus',
      'intro': '枝叶纤细如云片的文雅小绿植，适合案头。',
      'light': '半阴散射光，忌暴晒',
      'water': '保持盆土微润，约 4~6 天一次',
      'tip': '喜湿润空气，多喷雾；黄叶多因干热或积水',
    },
    {
      'name': '君子兰',
      'aliases': ['君子兰', '大花君子兰'],
      'latin': 'Clivia miniata',
      'intro': '观花观叶俱佳的温室花卉，叶片对称如扇。',
      'light': '明亮散射光，忌强光',
      'water': '盆土半干浇透，约 7~10 天一次',
      'tip': '忌积水烂根；冬春怕冻；开花前控水增光',
    },
    {
      'name': '橡皮树',
      'aliases': ['橡皮树', '印度榕'],
      'latin': 'Ficus elastica',
      'intro': '叶片厚实油亮的大型观叶植物，长势强健。',
      'light': '明亮散射光，较耐阴',
      'water': '表土干透浇透，约 7~10 天一次',
      'tip': '定期擦叶；顶端汁液微毒，修剪后洗手；通风防落叶',
    },
    {
      'name': '茉莉',
      'aliases': ['茉莉', '茉莉花'],
      'latin': 'Jasminum sambac',
      'intro': '香气清雅的常绿灌木，夏秋开花，喜酸喜光。',
      'light': '充足阳光，越晒花越多',
      'water': '保持盆土湿润，约 2~3 天一次夏季',
      'tip': '定期施酸性肥；花后修剪促分枝；通风防红蜘蛛',
    },
    {
      'name': '月季',
      'aliases': ['月季', '玫瑰', '蔷薇'],
      'latin': 'Rosa chinensis',
      'intro': '花期长的经典观花植物，需光足、通风好。',
      'light': '全日照，每日 6 小时以上',
      'water': '表土干即浇，约 2~3 天一次',
      'tip': '定期预防黑斑病/红蜘蛛；花后剪残花；薄肥勤施',
    },
    {
      'name': '铜钱草',
      'aliases': ['铜钱草', '香菇草'],
      'latin': 'Hydrocotyle vulgaris',
      'intro': '圆叶小巧的水生/半水生绿植，半水半土最好养。',
      'light': '明亮散射光，也耐半阴',
      'water': '喜水，半水半土常年保水，土培每日浇',
      'tip': '缺水即蔫，补水即恢复；光照足叶片更圆亮',
    },
    {
      'name': '薄荷',
      'aliases': ['薄荷', '留兰香'],
      'latin': 'Mentha haplocalyx',
      'intro': '清香可食用的香草，长势旺，适合厨房窗台。',
      'light': '充足散射光至直射',
      'water': '喜湿润，约 1~2 天一次，夏季勤浇',
      'tip': '勤掐顶促分枝；地栽易蔓延，建议盆栽；可食用可泡茶',
    },
    {
      'name': '波士顿蕨',
      'aliases': ['波士顿蕨', '蕨'],
      'latin': 'Nephrolepis exaltata',
      'intro': '羽状叶片的阴生绿植，适合卫生间等湿润处。',
      'light': '阴凉散射光，忌直射',
      'water': '保持盆土湿润，约 2~3 天一次',
      'tip': '喜高湿，多喷雾；怕干怕涝；冬季减水保暖',
    },
    {
      'name': '滴水观音',
      'aliases': ['滴水观音', '海芋', '姑婆芋'],
      'latin': 'Alocasia macrorrhizos',
      'intro': '叶片巨大的热带观叶植物，气势强，但全株有毒。',
      'light': '明亮散射光，耐阴',
      'water': '保持盆土湿润，约 4~6 天一次',
      'tip': '汁液有毒，避免入口与触碰眼；远离儿童宠物；多湿环境更精神',
    },
  ];

  /// 按名称/别名匹配本地养护库
  static Map<String, dynamic>? byName(String name) {
    if (name.isEmpty) return null;
    final n = name.trim();
    for (final e in entries) {
      if (e['name'] == n) return e;
      for (final a in (e['aliases'] as List<String>)) {
        if (n.contains(a) || a.contains(n)) return e;
      }
    }
    return null;
  }
}

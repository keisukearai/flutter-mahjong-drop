import 'package:flutter/material.dart';

enum TileSuit { man, pin, sou, honor }

enum HonorType { east, south, west, north, haku, hatsu, chun }

class Tile {
  final TileSuit suit;
  final int number;
  final HonorType? honor;

  const Tile.number(this.suit, this.number)
      : honor = null,
        assert(suit != TileSuit.honor),
        assert(number >= 1 && number <= 9);

  const Tile.honor(this.honor)
      : suit = TileSuit.honor,
        number = 0;

  bool get isHonor => suit == TileSuit.honor;
  bool get isTerminal => !isHonor && (number == 1 || number == 9);
  bool get isSimple => !isHonor && !isTerminal;
  bool get isDragon => isHonor &&
      (honor == HonorType.haku || honor == HonorType.hatsu || honor == HonorType.chun);

  String get label {
    if (isHonor) {
      return switch (honor!) {
        HonorType.east => '東', HonorType.south => '南',
        HonorType.west => '西', HonorType.north => '北',
        HonorType.haku => '白', HonorType.hatsu => '發',
        HonorType.chun => '中',
      };
    }
    return switch (suit) {
      TileSuit.man => '$number\n萬',
      TileSuit.pin => '$number\n筒',
      TileSuit.sou => '$number\n索',
      TileSuit.honor => '',
    };
  }

  String get numberStr => isHonor ? '' : '$number';
  String get suitStr {
    if (isHonor) return label;
    return switch (suit) {
      TileSuit.man => '萬', TileSuit.pin => '筒',
      TileSuit.sou => '索', TileSuit.honor => '',
    };
  }

  Color get bgColor {
    if (isHonor) {
      return switch (honor!) {
        HonorType.haku => const Color(0xFFF5F5F5),
        HonorType.hatsu => const Color(0xFFE8F5E9),
        HonorType.chun => const Color(0xFFFFEBEE),
        _ => const Color(0xFFF3E5F5),
      };
    }
    return switch (suit) {
      TileSuit.man => const Color(0xFFFFF0EE),
      TileSuit.pin => const Color(0xFFEEF4FF),
      TileSuit.sou => const Color(0xFFEEFFF4),
      TileSuit.honor => const Color(0xFFF5F5F5),
    };
  }

  Color get fgColor {
    if (isHonor) {
      return switch (honor!) {
        HonorType.haku => const Color(0xFF424242),
        HonorType.hatsu => const Color(0xFF1B5E20),
        HonorType.chun => const Color(0xFFB71C1C),
        _ => const Color(0xFF6A1B9A),
      };
    }
    return switch (suit) {
      TileSuit.man => const Color(0xFFE53935),
      TileSuit.pin => const Color(0xFF1E88E5),
      TileSuit.sou => const Color(0xFF43A047),
      TileSuit.honor => const Color(0xFF424242),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Tile && suit == other.suit && number == other.number && honor == other.honor;

  @override
  int get hashCode => Object.hash(suit, number, honor);

  @override
  String toString() => isHonor ? label : '$numberStr$suitStr';

  static int compare(Tile a, Tile b) {
    if (a.suit.index != b.suit.index) return a.suit.index.compareTo(b.suit.index);
    if (a.isHonor && b.isHonor) return (a.honor?.index ?? 0).compareTo(b.honor?.index ?? 0);
    return a.number.compareTo(b.number);
  }
}

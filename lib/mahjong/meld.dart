import 'tile.dart';

enum MeldType { sequence, triplet }

class Meld {
  final MeldType type;
  final List<Tile> tiles; // always sorted (sequence: ascending; triplet: same)

  const Meld(this.type, this.tiles);

  bool get isSequence => type == MeldType.sequence;
  bool get isTriplet => type == MeldType.triplet;

  /// Try to form a meld from exactly 3 tiles (order doesn't matter).
  static Meld? tryForm(Tile a, Tile b, Tile c) {
    // Triplet
    if (a == b && b == c) return Meld(MeldType.triplet, [a, b, c]);

    // Sequence: same non-honor suit, consecutive numbers
    if (a.isHonor || b.isHonor || c.isHonor) return null;
    if (a.suit != b.suit || b.suit != c.suit) return null;
    final sorted = [a, b, c]..sort(Tile.compare);
    if (sorted[1].number == sorted[0].number + 1 &&
        sorted[2].number == sorted[0].number + 2) {
      return Meld(MeldType.sequence, sorted);
    }
    return null;
  }

  @override
  String toString() => '${type.name}(${tiles.join(",")})';
}

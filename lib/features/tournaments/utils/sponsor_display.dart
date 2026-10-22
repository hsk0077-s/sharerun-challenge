/// 후원 이름으로 화면에 쓰는 기본 값. 수혜 단체가 정해지기 전에는 단체 이름을
/// 화면에 쓰지 않고, 기부하는 주체인 운영자로 표시한다.
const operatorSponsorName = '운영자';

/// 저장된 후원 이름을 화면용으로 바꾼다. 단체 이름(유니세프 등)이거나 비어 있으면
/// [operatorSponsorName]을 돌려주고, 그 밖의 후원사 이름은 그대로 둔다.
String displaySponsorName(String raw) {
  final name = raw.trim();
  if (name.isEmpty) return operatorSponsorName;
  final lower = name.toLowerCase();
  if (lower.contains('unicef') || lower.contains('유니세프')) {
    return operatorSponsorName;
  }
  return name;
}

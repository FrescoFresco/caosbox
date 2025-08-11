enum Tri { off, include, exclude }

extension TriX on Tri {
  Tri next() => switch (this) { Tri.off => Tri.include, Tri.include => Tri.exclude, Tri.exclude => Tri.off };
  String get name => switch (this) { Tri.off => 'off', Tri.include => 'include', Tri.exclude => 'exclude' };
}

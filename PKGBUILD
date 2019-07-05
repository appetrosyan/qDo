_realname="qDoList"
pkgname="${_realname,,}"	# viva Bash 4.0
url="https://github.com/appetrosyan/qDoList"
pkgver=v0.1.2.g85b2002
pkgrel=1
pkgdesc="A to-do list manager for KDE"
arch=("x86_64")
license=('GPL3')
depends=(qt5-declarative hicolor-icon-theme)
makedepends=(git)
source=("git+https://github.com/appetrosyan/qDoList")
sha256sums=('SKIP')

pkgver() {
    cd "$srcdir/$_realname"
    git describe --tags | sed -r 's/-/./g'
}

prepare() {
  cd "$srcdir/$_realname"
}

build() {
  cd "$srcdir/$_realname"
  qmake $_realname.pro 
  make 
}

package(){
    cd "$srcdir/$_realname"
    install -D -m755 $_realname "$pkgdir/usr/bin/$pkgname"
    install -D -m644 "Icons/qDo.svg" "$pkgdir/usr/share/icons/hicolor/scalable/apps/$_realname.svg"
}

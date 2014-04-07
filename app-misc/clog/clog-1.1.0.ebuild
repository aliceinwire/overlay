# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

EGIT_REPO_URI="git://tasktools.org/${PN}.git"
[[ ${PV} = 9999 ]] && inherit git-2

inherit eutils cmake-utils bash-completion-r1

DESCRIPTION="Clog is a colorized log tail utility."
HOMEPAGE="http://tasktools.org/projects/clog/"
[[ ${PV} = 9999 ]] || SRC_URI="http://taskwarrior.org/download/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos"
IUSE=""

src_prepare() {
	# use the correct directory locations
	sed -i -e "s:/usr/local/share/doc/clog/rc:${EPREFIX}/usr/share/clog/rc:" \
		doc/man/clog.1.in || die
}

src_configure() {
	mycmakeargs=(
		-DTASK_DOCDIR="${EPREFIX}"/usr/share/doc/${PF}
	)
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
}

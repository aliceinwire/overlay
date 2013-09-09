# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

EGIT_REPO_URI="git://tasktools.org/${PN}.git"
[[ ${PV} = 9999 ]] && inherit git-2

inherit eutils cmake-utils bash-completion-r1

DESCRIPTION="Anomaly can detect anomalous data in a numeric stream."
HOMEPAGE="http://tasktools.org/projects/anomaly/"
[[ ${PV} = 9999 ]] || SRC_URI="http://taskwarrior.org/download/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos"
IUSE=""

src_prepare() {
	# use the correct directory locations
	sed -i -e "s:/usr/local/share/doc/anomaly/rc:${EPREFIX}/usr/share/anomaly/rc:" \
		doc/man/anomaly.1.in || die
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

# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI="https://code.google.com/p/${PN}"
[[ ${PV} = 9999 ]] && inherit git-2

inherit eutils bash-completion-r1

DESCRIPTION="A lightweight multi-paradigm programming language."
HOMEPAGE="https://code.google.com/p/virgil/"
#[[ ${PV} = 9999 ]] || SRC_URI="http://taskwarrior.org/download/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~x64-macos"
IUSE=""

src_install() {
	dobin bin/virgil
	dobin bin/v3c-x86-linux
	dodoc doc/*/*/*
}

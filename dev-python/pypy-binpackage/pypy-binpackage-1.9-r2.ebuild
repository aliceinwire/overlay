# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/pypy/pypy-1.9-r2.ebuild,v 1.4 2013/02/17 22:45:18 floppym Exp $

EAPI=5

# pypy should be preferred, per upstream.
# that's the easiest way of forcing it.
PYTHON_COMPAT=( pypy{1_8,1_9,2_0} )
inherit check-reqs eutils multilib multiprocessing python-any-r1 toolchain-funcs vcs-snapshot versionator

MY_P=pypy-${PV}

DESCRIPTION="A fast, compliant alternative implementation of the Python language"
HOMEPAGE="http://pypy.org/"
SRC_URI="https://bitbucket.org/pypy/pypy/get/release-${PV}.tar.bz2 -> ${MY_P}.tar.bz2"

LICENSE="MIT"
SLOT=$(get_version_component_range 1-2 ${PV})
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
IUSE="bzip2 +jit ncurses sandbox shadowstack sse2"

DEPEND=">=sys-libs/zlib-1.1.3
	virtual/libffi
	virtual/libintl
	dev-libs/expat
	dev-libs/openssl
	bzip2? ( app-arch/bzip2 )
	ncurses? ( sys-libs/ncurses )
	app-arch/xz-utils
	${PYTHON_DEPS}"

S=${WORKDIR}/pypy-${PV}

pkg_pretend() {
	if [[ ! ${PYPY_BINPKG_STORE} ]]; then
		eerror "Please set PYPY_BINPKG_STORE to the location where built"
		eerror "packages are to be stored."

		die "Set PYPY_BINPKG_STORE."
	fi

	CHECKREQS_MEMORY="2G"
	use amd64 && CHECKREQS_MEMORY="4G"
	check-reqs_pkg_pretend
}

pkg_setup() {
	pkg_pretend
	python-any-r1_pkg_setup

	local cpu
	if use amd64; then
		# common denominator between Intel & AMD
		cpu='x86-64'
	elif use x86; then
		if use sse2; then
			# lowest with SSE2
			cpu='pentium-m'
		else
			# lowest with SSE, compat. with athlon-xp
			# TODO: do we want to support something older?
			cpu='pentium3'
		fi
	else
		die "Unsupported arch ${ARCH}"
	fi

	export CFLAGS="-march=${cpu} -mtune=generic -O2 -pipe"
	export CXXFLAGS=${CFLAGS}

	elog "CFLAGS: ${CFLAGS}"
}

src_prepare() {
	epatch "${FILESDIR}/${PV}-no-bytecode-4151f9c406b6.patch"
	epatch "${FILESDIR}/${PV}-scripts-location.patch"
	epatch "${FILESDIR}/${PV}-distutils.unixccompiler.UnixCCompiler.runtime_library_dir_option.patch"
	epatch "${FILESDIR}/${PV}-distutils-fix_handling_of_executables_and_flags.patch"
	epatch "${FILESDIR}/${PV}-ssl-threads-1-34b3b5aac082.patch"
	epatch "${FILESDIR}/${PV}-ssl-threads-2-25cd11066d95.patch"
	epatch "${FILESDIR}/${PV}-get_python_lib_standard_lib-04ea518e5b71.patch"
	epatch "${FILESDIR}/${PV}-more-ignored-ops-a9a8faa76bca.patch"
	epatch "${FILESDIR}/${PV}-more-ignored-ops-146ddf82a279.patch"
	epatch "${FILESDIR}/${PV}-pybuffer-release-double-decref-4ec2a5b49386.patch"
	epatch "${FILESDIR}/${PV}-signal-a33052b17f4e.patch"
	epatch "${FILESDIR}/${PV}-getargs-freelist-c26dc70ee340.patch"
	epatch "${FILESDIR}/${PV}-ssl-errors-25d3418150d2.patch"

	# The following is Gentoo-specific.
	epatch "${FILESDIR}/${PV}-no-static-hack.patch"

	epatch_user
}

src_compile() {
	tc-export CC

	local jit_backend
	if use jit; then
		jit_backend='--jit-backend='

		# We only need the explicit sse2 switch for x86.
		# On other arches we can rely on autodetection which uses
		# compiler macros. Plus, --jit-backend= doesn't accept all
		# the modern values...

		if use x86; then
			if use sse2; then
				jit_backend+=x86
			else
				jit_backend+=x86-without-sse2
			fi
		else
			jit_backend+=auto
		fi
	fi

	local args=(
		$(usex jit -Ojit -O2)
		$(usex shadowstack --gcrootfinder=shadowstack '')
		$(usex sandbox --sandbox '')

		${jit_backend}
		--make-jobs=$(makeopts_jobs)

		./pypy/translator/goal/targetpypystandalone.py
	)

	# Avoid linking against libraries disabled by use flags
	local opts=(
		bzip2:bz2
		ncurses:_minimal_curses
	)

	local opt
	for opt in "${opts[@]}"; do
		local flag=${opt%:*}
		local mod=${opt#*:}

		args+=(
			$(usex ${flag} --withmod --withoutmod)-${mod}
		)
	done

	set -- "${PYTHON}" ./pypy/translator/goal/translate.py --batch "${args[@]}"
	echo -e "\033[1m${@}\033[0m"
	"${@}" || die "compile error"
}

src_install() {
	local flags=( bzip2 jit ncurses sandbox shadowstack )
	use x86 && flags+=( sse2 )
	local f suffix="-${ARCH}"

	for f in ${flags[@]}; do
		use ${f} && suffix+="+${f}"
	done

	local BIN_P=pypy-bin-${PV}

	einfo "Zipping PyPy ..."
	mkdir "${BIN_P}${suffix}"{,/include} || die
	mv pypy-c "${BIN_P}${suffix}"/ || die
	mv include/pypy_* "${BIN_P}${suffix}"/include/ || die
	chmod +x "${BIN_P}${suffix}"/pypy-c || die

	tar -cf "${BIN_P}${suffix}.tar" "${BIN_P}${suffix}" || die
	xz -vz9 "${BIN_P}${suffix}.tar" || die
}

# Yup, very hacky.
pkg_preinst() {
	# integrity check.
	[[ ${PYPY_BINPKG_STORE} ]] || die 'PYPY_BINPKG_STORE unset, wtf?!'
	mkdir -p "${ROOT%/}${PYPY_BINPKG_STORE}" || die
	mv "${S}"/*.tar.xz "${ROOT%/}${PYPY_BINPKG_STORE}" || die
}

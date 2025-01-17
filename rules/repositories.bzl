"""Definitions for handling Bazel repositories used by the Apple rules."""

load(
    "@bazel_tools//tools/build_defs/repo:http.bzl",
    "http_archive",
    "http_file",
)
load(
    "@bazel_tools//tools/build_defs/repo:git.bzl",
    "new_git_repository",
)

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.

    Args:
      repo_rule: The repository rule to be executed (e.g.,
          `http_archive`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

def github_repo(name, project, repo, ref, sha256 = None, **kwargs):
    """Downloads a repository from GitHub as a tarball.

    Args:
        name: The name of the repository.
        project: The project (user or organization) on GitHub that hosts the repository.
        repo: The name of the repository on GitHub.
        ref: The reference to be downloaded. Can be any named ref, e.g. a commit, branch, or tag.
        sha256: The sha256 of the downloaded tarball.
        **kwargs: additional keyword arguments for http_archive.
    """

    github_url = "https://github.com/{project}/{repo}/archive/{ref}.zip".format(
        project = project,
        repo = repo,
        ref = ref,
    )
    http_archive(
        name = name,
        strip_prefix = "%s-%s" % (repo, ref.replace("/", "-")),
        url = github_url,
        sha256 = sha256,
        canonical_id = github_url,
        **kwargs
    )

def _get_bazel_version():
    bazel_version = getattr(native, "bazel_version", "")
    if bazel_version:
        parts = bazel_version.split(".")
        if len(parts) > 2:
            return struct(major = parts[0], minor = parts[1], patch = parts[2])

    # Unknown, but don't crash
    return struct(major = 0, minor = 0, patch = 0)

def rules_ios_dependencies(
        load_bzlmod_dependencies = True):
    """Fetches repositories that are public dependencies of `rules_ios`.

    Args:
        load_bzlmod_dependencies: if `True` loads dependencies that are available via bzlmod (set to True when using WORKSPACE, and False when using bzlmod)
    """

    if load_bzlmod_dependencies:
        _rules_ios_bzlmod_dependencies()

    # Non-bzlmod tool dependencies that are used in the rule APIs
    _rules_ios_tool_dependencies()

    # If legacy project generator is deprecated this can be removed.
    _rules_ios_legacy_xcodeproj_dependencies()

def rules_ios_dev_dependencies(
        load_bzlmod_dependencies = True):
    """
    Fetches repositories that are development dependencies of `rules_ios`

    Args:
        load_bzlmod_dependencies: if `True` loads dependencies that are available via bzlmod (set to True when using WORKSPACE, and False when using bzlmod)
    """

    if load_bzlmod_dependencies:
        _rules_ios_bzlmod_dev_dependencies()

    _rules_ios_test_dependencies()

def _rules_ios_bzlmod_dependencies():
    """
    Fetches repositories that are dependencies of `rules_ios` and available via bzlmod

    These are only included when using WORKSPACE, when using bzlmod they're loaded in MODULE.bazel
    """

    if _get_bazel_version().major == "5":
        _maybe(
            github_repo,
            name = "build_bazel_rules_swift",
            project = "bazelbuild",
            ref = "e0272df7d98a563c07aa2e78722cd8ce62549864",
            repo = "rules_swift",
            sha256 = "006743d481c477928796ad985ba32b591f5926cd590d32b207e018049b569594",
        )

        # LTS support. Some of our third party deps from bazelbuild org don't
        # support LTS but from time to time we'll evaluate supporting this to
        # allow us to all run on HEAD
        # For rules_apple, we maintain a tag rules_ios_1.0
        _maybe(
            github_repo,
            name = "build_bazel_rules_apple",
            ref = "6f93e73382a01595d576247db9fa886769536605",
            project = "bazelbuild",
            repo = "rules_apple",
            sha256 = "1618fc82e556ebc97ea360b8cacd3365ca3b0e0a85ccb32422468204843e752d",
        )
    else:
        _maybe(
            http_archive,
            name = "build_bazel_rules_swift",
            sha256 = "3a595a64afdcaf65b74b794661556318041466d727e175fa8ce20bdf1bb84ba0",
            url = "https://github.com/bazelbuild/rules_swift/releases/download/1.10.0/rules_swift.1.10.0.tar.gz",
        )

        _maybe(
            http_archive,
            name = "build_bazel_rules_apple",
            sha256 = "8ac4c7997d863f3c4347ba996e831b5ec8f7af885ee8d4fe36f1c3c8f0092b2c",
            url = "https://github.com/bazelbuild/rules_apple/releases/download/2.5.0/rules_apple.2.5.0.tar.gz",
        )

    _maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "b8a1527901774180afc798aeb28c4634bdccf19c4d98e7bdd1ce79d1fe9aaad7",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.4.1/bazel-skylib-1.4.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.4.1/bazel-skylib-1.4.1.tar.gz",
        ],
    )

    _maybe(
        http_archive,
        name = "rules_pkg",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.9.1/rules_pkg-0.9.1.tar.gz",
            "https://github.com/bazelbuild/rules_pkg/releases/download/0.9.1/rules_pkg-0.9.1.tar.gz",
        ],
        sha256 = "8f9ee2dc10c1ae514ee599a8b42ed99fa262b757058f65ad3c384289ff70c4b8",
    )

def _rules_ios_bzlmod_dev_dependencies():
    """
    Fetches repositories that are development dependencies of `rules_ios` and available via bzlmod.

    These are only included when using WORKSPACE, when using bzlmod they're loaded in MODULE.bazel
    """

    _maybe(
        http_archive,
        name = "buildifier_prebuilt",
        sha256 = "e46c16180bc49487bfd0f1ffa7345364718c57334fa0b5b67cb5f27eba10f309",
        strip_prefix = "buildifier-prebuilt-6.1.0",
        urls = [
            "http://github.com/keith/buildifier-prebuilt/archive/6.1.0.tar.gz",
        ],
    )

def _rules_ios_legacy_xcodeproj_dependencies():
    """Fetches the repositories that are dependencies of the legacy xcode project generator"""

    _maybe(
        http_archive,
        name = "com_github_yonaskolb_xcodegen",
        build_file_content = """\
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "xcodegen",
    src = "bin/xcodegen",
    out = "xcodegen",
    data = glob(["share/**/*"]),
    visibility = ["//visibility:public"],
)
""",
        canonical_id = "xcodegen-2.18.0-12-g04d6749",
        sha256 = "3742eee89850cea75367b0f67662a58da5765f66c1be9b4189a59529b4e5099e",
        strip_prefix = "xcodegen",
        urls = ["https://github.com/segiddins/XcodeGen/releases/download/2.18.0-12-g04d6749/xcodegen.zip"],
    )

def _rules_ios_tool_dependencies():
    """Fetches the repositories that are dependencies of `rules_ios`'s development tools."""

    _maybe(
        http_file,
        name = "tart",
        urls = ["https://github.com/bazel-ios/tart/releases/download/0.35.2/tart"],
        sha256 = "7b9f4f37054483e565c760525b7e9e9097053c361dc16306583bb2981a29a6ec",
    )

    _maybe(
        new_git_repository,
        name = "arm64-to-sim",
        remote = "https://github.com/bogo/arm64-to-sim.git",
        commit = "25599a28689fa42679f23eb0ff031ebe57d3bb9b",
        shallow_since = "1627075944 -0700",
        build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

swift_binary(
    name = "arm64-to-sim",
    srcs = glob(["Sources/arm64-to-sim/*.swift"]),
    visibility = ["//visibility:public"],
)
        """,
    )

def _rules_ios_test_dependencies():
    """Fetches the repositories that are dependencies of `rules_ios`'s tests."""

    _maybe(
        github_repo,
        name = "com_github_apple_swiftcollections",
        build_file = "@//tests/ios/frameworks/external-dependency:BUILD.com_github_apple_swiftcollections",
        project = "apple",
        ref = "0.0.3",
        repo = "swift-collections",
        sha256 = "e6f36a1f9bb163437b4e9bc8da641a6129f16af7799eb8418c4a35749ceb1ef7",
    )

    _maybe(
        http_archive,
        name = "TensorFlowLiteC",
        url = "https://dl.google.com/dl/cpdc/3895e5bf508673ae/TensorFlowLiteC-2.6.0.tar.gz",
        sha256 = "a28ce764da496830c0a145b46e5403fb486b5b6231c72337aaa8eaf3d762cc8d",
        build_file = "@//tests/ios/unit-test/test-imports-app:BUILD.TensorFlowLiteC",
        strip_prefix = "TensorFlowLiteC-2.6.0",
    )

    _maybe(
        http_archive,
        name = "GoogleMobileAdsSDK",
        url = "https://dl.google.com/dl/cpdc/e0dda986a9f84d14/Google-Mobile-Ads-SDK-8.10.0.tar.gz",
        sha256 = "0726df5d92165912c9e60a79504a159ad9b7231dda851abede8f8792b266dba5",
        build_file = "@//tests/ios/unit-test/test-imports-app:BUILD.GoogleMobileAds",
    )

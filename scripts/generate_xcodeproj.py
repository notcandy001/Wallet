#!/usr/bin/env python3
"""Generates apps/ios/Wallet.xcodeproj/project.pbxproj (no XcodeGen needed).
The app target compiles Wallet/ and WalletCore/Sources/WalletCore/ together."""
import hashlib, os, sys
IOS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "apps", "ios")
def uid(k): return hashlib.md5(k.encode()).hexdigest()[:24].upper()
objs = {}   # id -> (comment, body)
def add(i, comment, body): objs[i] = (comment, body)

sources, resources = [], []
def build_group(rel, name, gid_key, top=False):
    """Returns group id for directory rel (relative to IOS), recursively."""
    full = os.path.join(IOS, rel); kids = []
    for e in sorted(os.listdir(full)):
        p = os.path.join(full, e); r = os.path.join(rel, e)
        if e.startswith(".") or e == "Tests": continue
        if os.path.isdir(p) and e.endswith(".xcassets"):
            fid = uid("ref:" + r)
            add(fid, e, f'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = {e}; sourceTree = "<group>";')
            bid = uid("bf:" + r); add(bid, f"{e} in Resources", f"isa = PBXBuildFile; fileRef = {fid};")
            resources.append(bid); kids.append(fid)
        elif os.path.isdir(p):
            kids.append(build_group(r, e, "grp:" + r))
        elif e.endswith(".swift"):
            fid = uid("ref:" + r)
            add(fid, e, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {e}; sourceTree = "<group>";')
            bid = uid("bf:" + r); add(bid, f"{e} in Sources", f"isa = PBXBuildFile; fileRef = {fid};")
            sources.append(bid); kids.append(fid)
    gid = uid(gid_key)
    add(gid, name, "isa = PBXGroup; children = (" + ", ".join(kids) + f'); path = {rel if top else os.path.basename(rel)}; sourceTree = "<group>";')
    return gid

app_g = build_group("Wallet", "Wallet", "grp:Wallet", True)
core_g = build_group("WalletCore/Sources/WalletCore", "WalletCore", "grp:core", True)
product = uid("product"); add(product, "Wallet.app", 'isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Wallet.app; sourceTree = BUILT_PRODUCTS_DIR;')
prod_g = uid("grp:products"); add(prod_g, "Products", f'isa = PBXGroup; children = ({product}); name = Products; sourceTree = "<group>";')
root_g = uid("grp:root"); add(root_g, "", f'isa = PBXGroup; children = ({app_g}, {core_g}, {prod_g}); sourceTree = "<group>";')

src_phase, res_phase, fw_phase = uid("phase:src"), uid("phase:res"), uid("phase:fw")
add(src_phase, "Sources", "isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (" + ", ".join(sources) + "); runOnlyForDeploymentPostprocessing = 0;")
add(res_phase, "Resources", "isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (" + ", ".join(resources) + "); runOnlyForDeploymentPostprocessing = 0;")
add(fw_phase, "Frameworks", "isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;")

common = ['ALWAYS_SEARCH_USER_PATHS = NO','CLANG_ENABLE_MODULES = YES','ENABLE_STRICT_OBJC_MSGSEND = YES','GCC_NO_COMMON_BLOCKS = YES',
          'IPHONEOS_DEPLOYMENT_TARGET = 17.0','SDKROOT = iphoneos','SWIFT_VERSION = 5.0','ENABLE_USER_SCRIPT_SANDBOXING = YES']
def cfg(name, extra):
    i = uid("cfg:" + name); add(i, name, "isa = XCBuildConfiguration; buildSettings = { " + " ".join(s + ";" for s in common + extra) + f" }}; name = {name};"); return i
proj_d = cfg("proj-Debug", ['ONLY_ACTIVE_ARCH = YES','SWIFT_OPTIMIZATION_LEVEL = "-Onone"','SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG','GCC_OPTIMIZATION_LEVEL = 0']); objs[proj_d] = (objs[proj_d][0], objs[proj_d][1].replace("name = proj-Debug", "name = Debug"))
proj_r = cfg("proj-Release", ['SWIFT_OPTIMIZATION_LEVEL = "-O"','SWIFT_COMPILATION_MODE = wholemodule','VALIDATE_PRODUCT = YES']); objs[proj_r] = (objs[proj_r][0], objs[proj_r][1].replace("name = proj-Release", "name = Release"))
tgt = ['PRODUCT_NAME = Wallet','PRODUCT_BUNDLE_IDENTIFIER = com.example.wallet','MARKETING_VERSION = 0.1.0','CURRENT_PROJECT_VERSION = 1',
       'GENERATE_INFOPLIST_FILE = YES','INFOPLIST_KEY_CFBundleDisplayName = Wallet','INFOPLIST_KEY_UILaunchScreen_Generation = YES',
       'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait',
       'INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"',
       'ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon','ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor',
       'TARGETED_DEVICE_FAMILY = "1,2"','CODE_SIGN_STYLE = Automatic','LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks"','ENABLE_PREVIEWS = YES']
tgt_d = cfg("tgt-Debug", tgt); objs[tgt_d] = (objs[tgt_d][0], objs[tgt_d][1].replace("name = tgt-Debug", "name = Debug"))
tgt_r = cfg("tgt-Release", tgt); objs[tgt_r] = (objs[tgt_r][0], objs[tgt_r][1].replace("name = tgt-Release", "name = Release"))
proj_l, tgt_l = uid("list:proj"), uid("list:tgt")
add(proj_l, 'Build configuration list for PBXProject "Wallet"', f"isa = XCConfigurationList; buildConfigurations = ({proj_d}, {proj_r}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;")
add(tgt_l, 'Build configuration list for PBXNativeTarget "Wallet"', f"isa = XCConfigurationList; buildConfigurations = ({tgt_d}, {tgt_r}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;")
target = uid("target"); add(target, "Wallet", f'isa = PBXNativeTarget; buildConfigurationList = {tgt_l}; buildPhases = ({src_phase}, {fw_phase}, {res_phase}); buildRules = (); dependencies = (); name = Wallet; productName = Wallet; productReference = {product}; productType = "com.apple.product-type.application";')
project = uid("project"); add(project, "Project object", f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1600; LastUpgradeCheck = 1600; }}; buildConfigurationList = {proj_l}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = {root_g}; productRefGroup = {prod_g}; projectDirPath = ""; projectRoot = ""; targets = ({target});')

# sanity: every referenced id exists
import re
for i, (c, b) in objs.items():
    for ref in re.findall(r"\b[0-9A-F]{24}\b", b):
        assert ref in objs, f"dangling {ref} in {c}"
kinds = {}
for i, (c, b) in objs.items(): kinds.setdefault(re.match(r"isa = (\w+)", b).group(1), []).append(i)
out = ["// !$*UTF8*$!", "{", "\tarchiveVersion = 1;", "\tclasses = {", "\t};", "\tobjectVersion = 56;", "\tobjects = {", ""]
for k in sorted(kinds):
    out.append(f"/* Begin {k} section */")
    for i in sorted(kinds[k]):
        c, b = objs[i]; out.append(f"\t\t{i}" + (f" /* {c} */" if c else "") + f" = {{{b}}};")
    out.append(f"/* End {k} section */\n")
out += ["\t};", f"\trootObject = {project};", "}", ""]
d = os.path.join(IOS, "Wallet.xcodeproj"); os.makedirs(d, exist_ok=True)
open(os.path.join(d, "project.pbxproj"), "w").write("\n".join(out))
print(f"wrote {d}/project.pbxproj: {len(sources)} sources, {len(resources)} resources")

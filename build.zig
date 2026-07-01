const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lc86K_mod = b.createModule(.{
        .root_source_file = b.path("lc86K.zig"),
        .target = target,
        .optimize = optimize,
    });

    const decode_mod = b.createModule(.{
        .root_source_file = b.path("decode.zig"),
        .target = target,
        .optimize = optimize,
    });
    decode_mod.addImport("lc86K", lc86K_mod);

    const exe = b.addExecutable(.{
        .name = "lc86K",
        .root_module = lc86K_mod,
    });
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const test_mod = b.createModule(.{
        .root_source_file = b.path("tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_mod.addImport("lc86K", lc86K_mod);
    test_mod.addImport("decode", decode_mod);

    const tests = b.addTest(.{ .root_module = test_mod });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run the tests");
    test_step.dependOn(&run_tests.step);
}

const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("hoodie", "src/main.zig");
    exe.setBuildMode(mode);

    const run_cmd = exe.run();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const all_tests = b.addTest("src/all_test.zig");

    const test_step = b.step("test", "runs all tests");
    test_step.dependOn(&all_tests.step);

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}

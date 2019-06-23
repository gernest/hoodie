const Builder = @import("std").build.Builder;
const hoodie = @import("HOODIE.zig");

pub fn build(b: *Builder) void {
    hoodie.build(b);
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("hoodie", "src/hoodie.zig");
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

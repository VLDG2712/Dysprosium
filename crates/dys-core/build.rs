fn main() -> Result<(), Box<dyn std::error::Error>> {
    let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../../proto");
    let proto = root.join("dys/v1/dys.proto");
    println!("cargo:rerun-if-changed={}", proto.display());
    tonic_prost_build::configure().compile_protos(&[proto], &[root])?;
    Ok(())
}

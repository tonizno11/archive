echo "🔧 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing build dependencies..."
sudo apt install -y build-essential pkg-config libssl-dev curl git

echo "📥 Installing rustup (Rust toolchain manager)..."
curl https://sh.rustup.rs -sSf | sh -s -- -y

echo "🛠 Setting up environment variables..."
export PATH="$HOME/.cargo/bin:$PATH"
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc

echo "✅ Verifying Rust installation..."
source ~/.bashrc
rustc --version
cargo --version

echo "🎉 Rust setup complete!"

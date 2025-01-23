# Install Nix by following the instructions at https://nix.dev/install-nix

# Install GitHub CLI by following the instructions at https://github.com/cli/cli?tab=readme-ov-file#installation

gh repo clone  snothub/crossplane-demo

cd crossplane-demo

nix-shell --run $SHELL

chmod +x controller/00-intro.sh

./controller/00-intro.sh

source .env

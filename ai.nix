{ config, pkgs, inputs, ... }:

{
  # Ensure unfree packages are allowed (required for some AI tools)
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    # =========================================================================
    # AI Packages from Nixpkgs
    # =========================================================================
    pkgs.opencode        # Terminal-first AI coding agent
    # pkgs.codex         # Lightweight terminal coding agent (nixpkgs version)
    # pkgs.antigravity   # Google Antigravity platform (nixpkgs version)
    # pkgs.claude-code   # Claude Code CLI assistant
    # pkgs.aichat        # All-in-one CLI for OpenAI, Claude, Gemini, Ollama, etc.
    # pkgs.ollama        # CLI & runtime for running LLMs locally

    # =========================================================================
    # AI Packages from Flakes (Cutting-edge / Automated builds)
    # =========================================================================
    # Antigravity CLI ('agy') and IDE from jacopone/antigravity-nix
    inputs.antigravity.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
    # inputs.antigravity.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-ide

    # OpenAI Codex CLI from sadjow/codex-cli-nix
    inputs.codex.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Oh My Pi (OMP) terminal AI agent from can1357/oh-my-pi
    inputs.omp.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.hermes.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # ===========================================================================
  # Optional: Local LLM Service (Ollama)
  # Uncomment the block below to run Ollama as a background systemd service
  # ===========================================================================
  # services.ollama = {
  #   enable = true;
  #   acceleration = "cuda"; # Options: null, "cuda" (Nvidia), "rocm" (AMD)
  # };
}

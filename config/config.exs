import Config

if Mix.env() == :dev do
  # Setup git hooks for dev environments
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      commit_msg: [
        tasks: [
          {:file, "./scripts/verify_commit_msg.sh", include_hook_args: true}
        ]
      ]
    ]
end

defmodule Naive do
  defstruct [:id, :state]
end

defimpl CVRDT, for: Naive do
  def increment(cvrdt = %{state: state}), do: %{cvrdt | state: state + 1}
  def value(%{state: state}), do: state

  def join(%{id: id, state: state_1}, %{state: state_2}) do
    %Naive{id: id, state: state_1 + state_2}
  end
end

# Application config is global!
# it is expanded at compile time if you use releases
# What does that mean? Well at compile time any call to System.get_env in the
# config runs when the release is made, and the result is put into the release.

# This is fine if you build the release on the prod container, but we use CI
# so our release gets built on Circle's servers. That means those System.get_env
# calls run then. So we either have to put all our prod secrets onto Circle CI's
# servers (yuck) or those calls are gonna return nil. Which is also bad.

# What we want really is the config to be determined at runtime. That means, we
# want to be able to build a release, move that release to a different server
# and on app startup (i.e. without having to re-compile or re-build a release)
# have it read in that config - those System calls.

# Most deps should not require config, especially if that config can be runtime args
# E.g. Number. just a bunch of functions. If there are ways to configure it can be done
# as function arguments.

# We needed compile time config because our deps are built before our app boots
# But that means then, we can't define runtime config for our deps, because they
# have to boot before our app does, but they can't boot without the config.

# Some deps provide callbacks when the supervision tree starts. So these apps
# may have state, and they can be configured at runtime with this callback.
# phoenix does this and so does ecto.

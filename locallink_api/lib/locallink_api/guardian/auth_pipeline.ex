defmodule LocallinkApi.Guardian.AuthPipeline do
  @behaviour Plug
  alias Guardian.Plug, as: GPlug
  alias LocallinkApiWeb.AuthErrorHandler

  @guardian_module LocallinkApi.Guardian
  @otp_app :locallink_api

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> GPlug.VerifyHeader.call(init_verify_header())
    |> GPlug.EnsureAuthenticated.call(init_ensure_authenticated())
    |> GPlug.LoadResource.call(init_load_resource())
  end

  defp init_verify_header do
    GPlug.VerifyHeader.init(
      module: @guardian_module,
      otp_app: @otp_app,
      scheme: "Bearer",
      error_handler: AuthErrorHandler
    )
  end

  defp init_ensure_authenticated do
    GPlug.EnsureAuthenticated.init(
      module: @guardian_module,
      otp_app: @otp_app,
      error_handler: AuthErrorHandler
    )
  end

  defp init_load_resource do
    GPlug.LoadResource.init(
      module: @guardian_module,
      otp_app: @otp_app,
      allow_blank: false,
      error_handler: AuthErrorHandler
    )
  end
end

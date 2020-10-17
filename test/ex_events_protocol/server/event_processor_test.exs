defmodule ExEventsProtocol.Server.EventProcessorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Property.Generator
  alias ExEventsProtocol.Entities.Event
  alias ExEventsProtocol.Entities.EventBuilder
  alias ExEventsProtocol.Entities.RequestEvent

  alias ExEventsProtocol.Server.EventProcessor

  defmodule DummyRegistry do
    def event_handler_for("simulate_not_found", _), do: :not_found
    def event_handler_for(_, _), do: {:ok, DummyRegistry}

    def handle(%RequestEvent{name: "simulate_error"}) do
      :bad_response
    end

    def handle(%RequestEvent{name: "simulate_no_valid_response"} = request) do
      response = EventBuilder.response_for(request, fn _ -> {:ok, :dummy} end)
      %{response | auth: nil}
    end

    def handle(%RequestEvent{} = request) do
      EventBuilder.response_for(request, fn _ -> {:ok, :dummy} end)
    end
  end

  defp request_event do
    {:ok, request} =
      event_generator()
      |> Enum.at(1)
      |> Event.cast(RequestEvent)

    request
  end

  test "successfully process event" do
    assert {:ok, %{payload: payload}} =
             EventProcessor.process_event(request_event(), registry: DummyRegistry)

    assert payload == :dummy
  end

  test "should raise when registry configuration couldn't be found" do
    Application.delete_env(:ex_events_protocol, :registry)

    assert_raise RuntimeError,
                 "You must configure a EventRegistry " <>
                   "or pass it as option in EventProcessor.process_event/2",
                 fn ->
                   EventProcessor.process_event(request_event())
                 end
  end

  test "opts as a high precedence to choose a event registry" do
    Application.put_env(:ex_events_protocol, :registry, InvalidRegistry)

    assert {:ok, _response} =
             EventProcessor.process_event(request_event(), registry: DummyRegistry)
  end

  test "fallback to application env when registry isn't supplied by opts" do
    Application.put_env(:ex_events_protocol, :registry, DummyRegistry)

    assert {:ok, _response} = EventProcessor.process_event(request_event())
  end

  test "response should be badProtocol when event isn't valid" do
    request = %{request_event() | identity: nil}

    assert {:error, %{name: name, payload: validation_erros}} =
             EventProcessor.process_event(request, registry: DummyRegistry)

    assert String.ends_with?(name, ":badProtocol")
    assert validation_erros == %{properties: %{identity: %{type: :map, value: nil}}}
  end

  test "response should be badProtocol when event handle response isn't valid" do
    request = %{request_event() | name: "simulate_no_valid_response"}

    assert {:error, %{name: name, payload: validation_erros}} =
             EventProcessor.process_event(request, registry: DummyRegistry)

    assert String.ends_with?(name, ":badProtocol")
    assert validation_erros == %{properties: %{auth: %{type: :map, value: nil}}}
  end

  test "response should be :eventNotFound when no handler found for the given event" do
    request = %{request_event() | name: "simulate_not_found"}

    assert {:error, %{name: name}} =
             EventProcessor.process_event(request, registry: DummyRegistry)

    assert String.ends_with?(name, ":eventNotFound")
  end

  test "response should be :error whenever a unhandled resonse is found" do
    request = %{request_event() | name: "simulate_error"}

    assert {:error, %{name: name, payload: payload}} =
             EventProcessor.process_event(request, registry: DummyRegistry)

    assert String.ends_with?(name, ":error")
    assert payload == %{code: "UNHANLDED_ERROR", message: ":bad_response"}
  end
end

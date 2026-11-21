-- NUM INPUT FIELD

-- This is functionally the same as a normal text input but with a different text input func
function RerollSurplus.UI.create_num_input(args)
  args = args or {}
  args.prompt_text = args.prompt_text or localize('k_enter_text')
  args.current_prompt_text = ''
  args.id = args.id or "num_input"

  local ret = create_text_input(args)
  ret.nodes[1].nodes[1].nodes[1].config.func = 'surplus_num_input'
  return ret
end

G.FUNCS.surplus_num_input = function(e)
  e.from_num_input = true
  G.FUNCS.text_input(e)
end

RerollSurplus.Hook("before", G.FUNCS, "text_input", function(e)
  RerollSurplus.nums_only = e.from_num_input and true
end)

-- I can't think of another way to guarantee that the value gets converted back to a number safely.
RerollSurplus.Hook("after", _G, "TRANSPOSE_TEXT_INPUT", function()
  if RerollSurplus.nums_only then
    local hook_config = G.CONTROLLER.text_input_hook.config.ref_table
    hook_config.ref_table[hook_config.ref_value] = type(tonumber(GET_TEXT_FROM_INPUT())) == "number" and tonumber(GET_TEXT_FROM_INPUT()) or 0
  end
end)
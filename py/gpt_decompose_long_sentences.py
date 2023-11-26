import openai
import re
import json

'''
Example (from "Comment on Glenn Rudebusch's 'Do Measures of Monetary Policy in a VAR Make Sense?'" by Christopher Sims, 1998)
'The literature accordingly has begun attracting vigorous criticism, both from economists comforable with one version or another of conventional wisdom and from economists comfortable with the currently fashionable view that macroeconomics, properly executed, never requires thinking about more than one regression equation at a time.'
'''

def gpt_decompose_long_sentences_simple(gpt_prompt, openai_model_ChatCompletion = 'gpt-4'):
	gpt_prompt_system = 'Decompose the long sentence into several short simple sentences'
	completion = openai.chat.completions.create(
		model = openai_model_ChatCompletion,
		messages = [
			{'role': 'system', 'content': gpt_prompt_system},
			{'role': 'user', 'content': gpt_prompt}
			]
		)
	gpt_prompt_decomposed = completion.choices[0].message.content
	decompose_output = {
		'gpt_prompt': gpt_prompt,
		'gpt_prompt_decomposed': gpt_prompt_decomposed
	}
	return decompose_output

def count_words(input_text):
	input_text_sentences = re.split('[.?!]', input_text)[:-1]
	if input_text_sentences == []:
		input_text_sentences = [input_text]
	count_words_return_num_sentence = len(input_text_sentences)
	if count_words_return_num_sentence == 1:
		count_words_return_num_word_total = str(len(input_text.split()))
		count_words_return_num_word_max_sentence = count_words_return_num_word_total
	else:
		count_words_return_nums_word = [len(input_text_sentence.split()) for input_text_sentence in input_text_sentences]
		count_words_return_num_word_total = sum(count_words_return_nums_word)
		count_words_return_num_word_max_sentence = max(count_words_return_nums_word)
	count_words_return = {
		'num_word_total': count_words_return_num_word_total,
		'num_sentence': count_words_return_num_sentence,
		'num_word_max_sentence': count_words_return_num_word_max_sentence,
		'language': 'en'
	}
	return json.dumps(count_words_return)

def gpt_decompose_long_sentences(gpt_prompt, openai_model_ChatCompletion = 'gpt-4'):

	gpt_prompt_system = 'Decompose the long sentence into several short simple sentences'

	completion = openai.chat.completions.create(
		model = openai_model_ChatCompletion,
		messages = [
			{'role': 'system', 'content': gpt_prompt_system},
			{'role': 'user', 'content': gpt_prompt}
			]
		)
	gpt_prompt_decomposed = completion.choices[0].message.content

	gpt_prompt_function_user = 'Count the number of words in the following sentence: ' + gpt_prompt
	gpt_prompt_functions = [
		{
			'name': 'count_words',
			'description': 'Count the number of words in the given string, and return the total number of words, the number of sentences, and the maximum number of words in a sentence',
			'parameters': {
				'type': 'object',
				'properties': {
					'input_text': {
						'type': 'string',
						'description': 'The input text'
					}
				}
			},
			'required': ['input_text']
		}
	]
	gpt_prompt_tools = [
		{
			'type': 'function',
			'function': gpt_prompt_functions[0]
		}
	]

	completion_function_messages = [
		{'role': 'user', 'content': gpt_prompt_function_user}
	]
	completion_function = openai.chat.completions.create(
		model = openai_model_ChatCompletion,
		messages = completion_function_messages,
		tools = gpt_prompt_tools,
		tool_choice = 'auto'
		)
	completion_function_response_message = completion_function.choices[0].message
	tool_calls = completion_function_response_message.tool_calls
	if tool_calls:
		functions_available = {
			'count_words': count_words
		}
		tool_call = tool_calls[0]
		function_name = tool_call.function.name
		function_to_call = functions_available[function_name]
		function_arguments = json.loads(tool_call.function.arguments)
		function_response = function_to_call(
			input_text = function_arguments.get('input_text')
			)
		completion_function_messages.append(completion_function_response_message)
		completion_function_messages.append(
			{'tool_call_id': tool_call.id, 'role': 'tool', 'name': function_name, 'content': function_response}
			)
		completion_function_result = openai.chat.completions.create(
			model = openai_model_ChatCompletion,
			messages = completion_function_messages
			)

	completion_function_messages.append({'role': 'assistant', 'content': completion_function_result.choices[0].message.content})
	gpt_prompt_function_user_decomposed = 'Count the number of words in the following sentence and compare it with the previous sentence, including the number of sentences and the maximum number of words in a sentence: ' + gpt_prompt_decomposed
	completion_function_messages.append({'role': 'user', 'content': gpt_prompt_function_user_decomposed})
	completion_function_decomposed = openai.chat.completions.create(
		model = openai_model_ChatCompletion,
		messages = completion_function_messages,
		tools = gpt_prompt_tools,
		tool_choice = 'auto'
		)
	completion_function_response_message_decomposed = completion_function_decomposed.choices[0].message
	tool_calls = completion_function_response_message_decomposed.tool_calls
	if tool_calls:
		functions_available = {
			'count_words': count_words
		}
		tool_call = tool_calls[0]
		function_arguments_decomposed = json.loads(tool_call.function.arguments)
		function_response_decomposed = function_to_call(
			input_text = function_arguments_decomposed.get('input_text')
			)
		completion_function_messages.append(completion_function_response_message_decomposed)
		completion_function_messages.append(
			{'tool_call_id': tool_call.id, 'role': 'tool', 'name': function_name, 'content': function_response_decomposed}
			)
		completion_function_result_decomposed = openai.chat.completions.create(
			model = openai_model_ChatCompletion,
			messages = completion_function_messages
			)

	decompose_output = {
		'gpt_prompt': gpt_prompt,
		'gpt_prompt_decomposed': gpt_prompt_decomposed,
		'completion_function_result_content': completion_function_result.choices[0].message.content,
		'completion_function_result_decomposed': completion_function_result_decomposed.choices[0].message.content
	}
	return decompose_output

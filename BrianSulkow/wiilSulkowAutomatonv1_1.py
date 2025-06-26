import random

class Automaton:
    def __init__(self, transitions, results, alphabet, states):
        self.rules = {
            'transitions': transitions,
            'results': results
            }
        self.alphabet = alphabet
        self.states = states
        

    def process_input(self, input_str, start_state, abs_state, mutation_num):
        rules = self.rules.copy()
        for _ in range(mutation_num):
            choice = random.choice(list(rules.keys()))

            if choice == 'transitions':
                key = random.choice(list(rules['transitions'].keys()))
                new_state = random.choice(self.states)
                rules['transitions'][key] = new_state
            else:
                key = random.choice(list(rules['results'].keys()))
                new_result = random.choice(self.alphabet)
                rules['results'][key] = new_result
                        
        current_state = start_state 
        for i in input_str:
            if current_state == abs_state:
                    return rules['results'][abs_state]
            
            key = (current_state, i)
            if key in rules['transitions']:
                current_state = rules['transitions'][key]
            else:
                return None

            
        return rules['results'][current_state]

transitions = {
    ('s0', '0'): 's1',
    ('s0', '1'): 's0',
    ('s1', '0'): 's1',
    ('s1', '1'): 's2',
    ('s2', '0'): 's2',
    ('s2', '1'): 's2',
}

results = {
    's0': '0',
    's1': '1',
    's2': '1',
}

alphabet = ['0', '1']

input_str = '101'
start_state = 's0'

automaton = Automaton(transitions, results, alphabet)
final_state = automaton.process_input(input_str, start_state, 's2', 1)
print(final_state)

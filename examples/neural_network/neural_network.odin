package neural_network

import "core:fmt"

//  input  hidden  output
//
//           h1
//    i1
//           h2     o1
//    i2
//           h3     o2
//    i3
//           h4

input_node_count :: 3
hidden_node_count :: 4
output_node_count :: 2

neural_network :: struct {
	input_layer    : [input_node_count]f32,
	hidden_layer   : [hidden_node_count]f32,
	output_layer   : [output_node_count]f32,
	input_weights  : matrix[input_node_count, hidden_node_count]f32,
	hidden_weights : matrix[hidden_node_count, output_node_count]f32,
}

calculate_network :: proc(nn: ^neural_network) {
	nn.hidden_layer = nn.input_layer * nn.input_weights
	nn.output_layer = nn.hidden_layer * nn.hidden_weights
}

dump_network :: proc(nn: ^neural_network) {
	fmt.println("----------------------------------------")
	fmt.printfln("input_layer    : %v", nn.input_layer)
	fmt.printfln("input_weights  : %v", nn.input_weights)
	fmt.printfln("hidden_layer   : %v", nn.hidden_layer)
	fmt.printfln("hidden_weights : %v", nn.hidden_weights)
	fmt.printfln("output_layer   : %v", nn.output_layer)
}

main :: proc() {
	fmt.println("neural network")

	nn: neural_network

	random_vector(&nn.input_layer)
	random_matrix(&nn.input_weights)
	random_matrix(&nn.hidden_weights)
	dump_network(&nn)
	calculate_network(&nn)
	dump_network(&nn)
}

/* output
neural network
----------------------------------------
input_layer    : [0.062651277, 0.43289304, 0.21359193]
input_weights  : matrix[0.8074821, 0.9356851, 0.53196949, 0.28380913; 0.13033503, 0.36638445, 0.67374569, 0.6660307; 0.04701966, 0.61407858, 0.98140669, 0.8147851]
hidden_layer   : [0, 0, 0, 0]
hidden_weights : matrix[0.2677508, 0.36479175; 0.27068633, 0.76687568; 0.7011826, 0.1952542; 0.018148541, 0.3696351]
output_layer   : [0, 0]
----------------------------------------
input_layer    : [0.062651277, 0.43289304, 0.21359193]
input_weights  : matrix[0.8074821, 0.9356851, 0.53196949, 0.28380913; 0.13033503, 0.36638445, 0.67374569, 0.6660307; 0.04701966, 0.61407858, 0.98140669, 0.8147851]
hidden_layer   : [0.11705393, 0.34838939, 0.53460896, 0.4801326]
hidden_weights : matrix[0.2677508, 0.36479175; 0.27068633, 0.76687568; 0.7011826, 0.1952542; 0.018148541, 0.3696351]
output_layer   : [0.50921774, 0.59173024]
*/

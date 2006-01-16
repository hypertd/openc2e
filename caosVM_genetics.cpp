/*
 *  caosVM_genetics.cpp
 *  openc2e
 *
 *  Created by Alyssa Milburn on Fri Dec 9 2005.
 *  Copyright (c) 2005 Alyssa Milburn. All rights reserved.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 */

#include "caosVM.h"

/**
 GENE CLON (command) dest_agent (agent) dest_slot (integer) src_agent (agent) src_slot (integer)
 %status stub
 
 Clone a genome. A new moniker is created.
*/
void caosVM::c_GENE_CLON() {
	VM_PARAM_INTEGER(src_slot)
	VM_PARAM_VALIDAGENT(src_agent)
	VM_PARAM_INTEGER(dest_slot)
	VM_PARAM_VALIDAGENT(dest_agent)

	// TODO
}

/**
 GENE CROS (command) dest_agent (agent) dest_slot (integer) mum_agent (agent) mum_slot (integer) dad_agent (agent) dad_slot (integer) mum_mutation_chance (integer) mum_mutation_degree (integer) dad_mutation_chance (integer) dad_mutation_degree (integer)
 %status stub

 Cross two genomes, creating a new one.
*/
void caosVM::c_GENE_CROS() {
	VM_PARAM_INTEGER(dad_mutation_degree)
	VM_PARAM_INTEGER(dad_mutation_chance)
	VM_PARAM_INTEGER(mum_mutation_degree)
	VM_PARAM_INTEGER(mum_mutation_chance)
	VM_PARAM_INTEGER(dad_slot)
	VM_PARAM_VALIDAGENT(dad_agent)
	VM_PARAM_INTEGER(mum_slot)
	VM_PARAM_VALIDAGENT(mum_agent)
	VM_PARAM_INTEGER(dest_slot)
	VM_PARAM_VALIDAGENT(dest_agent)

	// TODO
}

/**
 GENE KILL (command) agent (agent) slot (integer)
 %status stub

 Delete a genome from a slot.
*/
void caosVM::c_GENE_KILL() {
	VM_PARAM_INTEGER(slot)
	VM_PARAM_VALIDAGENT(agent)

	// TODO
}

/**
 GENE LOAD (command) agent (agent) slot (integer) genefile (string)
 %status stub

 Load a genome file into a slot. You can use * and ? wildcards in the filename.
*/
void caosVM::c_GENE_LOAD() {
	VM_PARAM_STRING(genefile)
	VM_PARAM_INTEGER(slot)
	VM_PARAM_VALIDAGENT(agent)

	// TODO
}

/**
 GENE MOVE (command) dest_agent (agent) dest_slot (integer) src_agent (agent) src_slot (integer)
 %status stub

 Move a genome to another slot.
*/
void caosVM::c_GENE_MOVE() {
	VM_PARAM_INTEGER(src_slot)
	VM_PARAM_VALIDAGENT(src_agent)
	VM_PARAM_INTEGER(dest_slot)
	VM_PARAM_VALIDAGENT(dest_agent)

	// TODO
}

/**
 GTOS (string) slot (integer)
 %status stub
 
 Return the moniker stored in the given gene slot of the target agent.
*/
void caosVM::v_GTOS() {
	VM_PARAM_INTEGER(slot)
	result.setString(""); // TODO
}

/**
 MTOA (agent) moniker (string)
 %status stub

 Return the agent which has the given moniker stored in a gene slot, or NULL if none.
*/
void caosVM::v_MTOA() {
	VM_PARAM_STRING(moniker)
	result.setAgent(0); // TODO
}

/**
 MTOC (agent) moniker (string)
 %status stub

 Return the live creature with the given moniker, or NULL if none.
*/
void caosVM::v_MTOC() {
	VM_PARAM_STRING(moniker)
	result.setAgent(0); // TODO
}

/* vim: set noet: */

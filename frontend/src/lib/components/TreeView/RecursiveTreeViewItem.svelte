<script lang="ts">
	import { createEventDispatcher, getContext, onMount } from 'svelte';
	import RecursiveTreeViewItem from './RecursiveTreeViewItem.svelte';
	import TreeViewItem from './TreeViewItem.svelte';
	import type { TreeViewNode } from './types';

	onMount(async () => {
		if (selection) {
			// random number as name
			name = String(Math.random());

			// remove relational links
			if (!relational) treeItems = [];
		}
	});

	interface Props {
		/** Provide data-driven nodes. */
		nodes?: TreeViewNode[];
		/**
		 * provides id's of expanded nodes
		 * @type {string[]}
		 */
		expandedNodes?: string[];
		/**
		 * provides id's of disabled nodes
		 * @type {string[]}
		 */
		disabledNodes?: string[];
		/**
		 * provides id's of checked nodes
		 * @type {string[]}
		 */
		checkedNodes?: string[];
		/**
		 * provides id's of indeterminate nodes
		 * @type {string[]}
		 */
		indeterminateNodes?: string[];
		// important to pass children up to items (recursively)
		treeItems?: TreeViewItem[];
	}

	let {
		nodes = [],
		expandedNodes = $bindable([]),
		disabledNodes = $bindable([]),
		checkedNodes = $bindable([]),
		indeterminateNodes = $bindable([]),
		treeItems = $bindable([])
	}: Props = $props();
	let childrenNodes: TreeViewItem[][] = $state(Array(nodes.length).fill([]));
	let rnodes = $state(nodes);

	// Context API
	let selection: boolean = getContext('selection');
	let multiple: boolean = getContext('multiple');
	let relational: boolean = getContext('relational');

	// Locals
	let group: unknown = $state(multiple ? [] : '');
	let name = $state('');

	// events
	const dispatch = createEventDispatcher();

	function toggleNode(node: TreeViewNode, open: boolean) {
		// toggle only nodes with children
		if (!node.children?.length) return;
		if (open) {
			// node is not registered as opened
			if (!expandedNodes.includes(node.id)) {
				expandedNodes.push(node.id);
				expandedNodes = expandedNodes;
			}
		} else {
			// node is registered as open
			if (expandedNodes.includes(node.id)) {
				expandedNodes.splice(expandedNodes.indexOf(node.id), 1);
				expandedNodes = expandedNodes;
			}
		}
	}

	function checkNode(node: TreeViewNode, checked: boolean, indeterminate: boolean) {
		if (checked) {
			// node is not registered as checked
			if (!checkedNodes.includes(node.id)) {
				checkedNodes.push(node.id);
				checkedNodes = checkedNodes;
			}

			// node is not indeterminate but registered as indeterminate
			if (!indeterminate && indeterminateNodes.includes(node.id)) {
				indeterminateNodes.splice(indeterminateNodes.indexOf(node.id), 1);
				indeterminateNodes = indeterminateNodes;
			}
		} else {
			// node is registered as checked
			if (checkedNodes.includes(node.id)) {
				checkedNodes.splice(checkedNodes.indexOf(node.id), 1);
				checkedNodes = checkedNodes;
			}

			// node is indeterminate but not registered as indeterminate
			if (indeterminate && !indeterminateNodes.includes(node.id)) {
				indeterminateNodes.push(node.id);
				indeterminateNodes = indeterminateNodes;
				// node is not indeterminate but registered as indeterminate
			} else if (!indeterminate && indeterminateNodes.includes(node.id)) {
				indeterminateNodes.splice(indeterminateNodes.indexOf(node.id), 1);
				indeterminateNodes = indeterminateNodes;
			}
		}
	}

	if (selection) {
		if (multiple) {
			nodes.forEach((node) => {
				if (!Array.isArray(group)) return;
				if (checkedNodes.includes(node.id) && !group.includes(node.id)) {
					group.push(node.id);
				}
			});
			group = group;
		} else {
			nodes.forEach((node) => {
				if (checkedNodes.includes(node.id) && group !== node.id) {
					group = node.id;
				}
			});
		}
	}

	function hasMappingInference(node: TreeViewNode) {
		const length = Object.keys(node.contentProps?.mapping_inference ?? {}).length;
		if (length > 0) {
			return true;
		}
		return false;
	}

	function areAllChildrenHiddenRecursive(node: TreeViewNode): boolean {
		if (!node.children || node.children.length === 0) return false;
		return node.children.every(
			(child) => child.contentProps.hidden || areAllChildrenHiddenRecursive(child)
		);
	}
</script>

{#if nodes && nodes.length > 0}
	{#each rnodes as node, i}
		<TreeViewItem
			bind:this={treeItems[i]}
			bind:childrenProp={childrenNodes[i]}
			bind:group
			bind:name
			bind:value={node.id}
			classProp={node?.contentProps?.hidden === true || areAllChildrenHiddenRecursive(node)
				? 'hidden'
				: ''}
			mappingInference={hasMappingInference(node)}
			hideLead={!node.lead}
			hideChildren={!node.children || node.children.length === 0}
			open={expandedNodes.includes(node.id)}
			disabled={disabledNodes.includes(node.id)}
			checked={checkedNodes.includes(node.id)}
			indeterminate={indeterminateNodes.includes(node.id)}
			onToggle={(isOpened) => {
				toggleNode(node, isOpened);
				dispatch('toggle', {
					id: node.id
				});
			}}
			on:groupChange={(e) => checkNode(node, e.detail.checked, e.detail.indeterminate)}
			on:click={() =>
				dispatch('click', {
					id: node.id
				})}
		>
			{#if typeof node.content === 'string'}
				{node.content}
			{:else}
				<node.content {...node.contentProps} />
			{/if}
			{#snippet lead()}
				{#if typeof node.lead === 'string'}
					{node.lead}
				{:else}
					<node.lead {...node.leadProps} />
				{/if}
			{/snippet}
			{#snippet childrenSlot()}
				<RecursiveTreeViewItem
					nodes={node.children}
					bind:expandedNodes
					bind:disabledNodes
					bind:checkedNodes
					bind:indeterminateNodes
					bind:treeItems={childrenNodes[i]}
					on:click={(e) =>
						dispatch('click', {
							id: e.detail.id
						})}
					on:toggle={(e) =>
						dispatch('toggle', {
							id: e.detail.id
						})}
				/>
			{/snippet}
		</TreeViewItem>
	{/each}
{/if}

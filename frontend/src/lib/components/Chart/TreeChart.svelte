<script lang="ts">
	import { onMount } from 'svelte';

	interface treeType {
		name: string;
		children: treeType[];
	}
	interface Props {
		width?: string;
		height?: string;
		classesContainer?: string;
		title?: string;
		name?: string;
		tree: treeType[];
	}

	let {
		width = 'w-auto',
		height = 'h-full',
		classesContainer = '',
		title = '',
		name = '',
		tree
	}: Props = $props();

	const chart_id = `${name}_div`;
	onMount(async () => {
		const echarts = await import('echarts');
		let chart_t = echarts.init(document.getElementById(chart_id), null, { renderer: 'svg' });
		// specify chart configuration item and data

		var option = {
			tooltip: {
				trigger: 'item',
				triggerOn: 'mousemove'
			},
			color: ['#625FFF'],
			title: { text: title },
			series: [
				{
					type: 'tree',
					roam: true,
					orient: 'vertical',
					data: [tree],
					symbol: 'square',
					symbolSize: 30,
					initialTreeDepth: 1,
					label: {
						position: 'left',
						verticalAlign: 'middle',
						align: 'right',
						fontSize: 13
					},

					leaves: {
						label: {
							position: 'right',
							verticalAlign: 'middle',
							align: 'right'
						}
					},

					emphasis: {
						focus: 'descendant'
					},

					expandAndCollapse: true,
					animationDuration: 550,
					animationDurationUpdate: 750
				}
			]
		};

		// console.debug(option);

		// use configuration item and data specified to show chart
		chart_t.setOption(option);

		window.addEventListener('resize', function () {
			chart_t.resize();
		});
	});
</script>

{#if tree.length === 0}
	<div class="flex flex-col justify-center items-center h-full">
		<span class="text-center text-gray-600"
			>Not enough data yet. Refresh when more content is available.</span
		>
	</div>
{:else}
	<div id={chart_id} class="{height} {width} {classesContainer}"></div>
{/if}

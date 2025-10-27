<?php

namespace Tests\Feature;

use Tests\TestCase;

class ExampleTest extends TestCase
{
	/**
	 * A basic test example.
	 *
	 * @return void
	 */
	public function test_basic_test()
	{
		$this->withoutExceptionHandling();
		$response = $this->get('/user/login');

		$response->assertStatus(200);
	}
}
